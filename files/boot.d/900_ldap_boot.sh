#!/usr/bin/env bash

set -e

config_db=${IMPORT_DIR}${IMPORT_CONFIG_FILE}
data_db=${IMPORT_DIR}${IMPORT_DATA_FILE}
slapd_base_path="/etc/ldap/slapd.d"

# import config
if [ -e ${config_db} ]; then
    echo -en '\033[1;37;44m   ... import config db \033[0m'
    # clean up existing config
    rm -rf "${slapd_base_path}"/* /var/lib/ldap/*
    # import config
    slapadd -F "${slapd_base_path}" -n 0 -l ${config_db}
    # mark the config import file as imported
    mv ${config_db} ${config_db}.$(date ${DATE_FORMAT})
    echo ' ... done'
    initial_run=false
fi

# import data
if [ -e ${data_db} ]; then
    echo -en '\033[1;37;44m   ... import data db \033[0m'
    # clean up existing data
    rm -rf /var/lib/ldap/*
    # import data
    slapadd -F "${slapd_base_path}" -n 1 -l ${data_db}
    # mark the data import file as imported
    mv ${data_db} ${data_db}.$(date ${DATE_FORMAT})
    echo ' ... done'
    initial_run=false
fi

# configure slapd
if [ ! "$(ls -A "${slapd_base_path}")" ] || [[ "${FORCE_RECONFIGURE}" == "true" ]]; then

    # check if we could continue with initiation

    break=false
    if [ -z ${LDAP_ADMIN_PW+x} ]; then
        echo -e "\033[1;41;30m ERROR: \033[0m ENV variable \033[1;42;33m LDAP_ADMIN_PW \033[0m not set, so we cannot initialize the LDAP."
        break=true
    fi
    if [ -z ${LDAP_DOMAIN+x} ]; then
        echo -e "\033[1;41;30m ERROR: \033[0m ENV variable \033[1;42;33m LDAP_DOMAIN \033[0m not set, so we cannot initialize the LDAP."
        break=true
    fi
    # check both manadtory variables and only break the container startup if one of them or both are unset
    if [[ "${break}" == "true" ]]; then
        exit 1
    fi

    echo -e '\033[1;42;97m Now starting configuration of slapd \033[0m'

    # now configure the SLAPD
    cat <<EOF | debconf-set-selections
        slapd slapd/internal/generated_adminpw password ${LDAP_ADMIN_PW}
        slapd slapd/internal/adminpw password ${LDAP_ADMIN_PW}
        slapd slapd/password2 password ${LDAP_ADMIN_PW}
        slapd slapd/password1 password ${LDAP_ADMIN_PW}
        slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
        slapd slapd/domain string ${LDAP_DOMAIN}
        slapd shared/organization string ${LDAP_ORGANISATION:=${LDAP_DOMAIN}}
        slapd slapd/backend string ${LDAP_BACKEND^^}
        slapd slapd/purge_database boolean true
        slapd slapd/move_old_database boolean true
        slapd slapd/allow_ldap_v2 boolean false
        slapd slapd/no_configuration boolean false
        slapd slapd/dump_database select when needed
EOF
    dpkg-reconfigure -f noninteractive slapd >/dev/null 2>&1

    # configure BaseDN
    if [ ! -z ${LDAP_BASEDN+x} ]; then
        basedn="${LDAP_BASEDN}"
    else
        dc=""
        IFS="."; declare -a dc_elements=($LDAP_DOMAIN); unset IFS
        for dc_e in "${dc_elements[@]}"; do
            dc="${dc},dc=${dc_e}"
        done
        # the first character is a `,` – that has to be omitted
        basedn="${dc:1}"
    fi

    echo -e "\033[1;37;44m   ... BaseDN retrieved as \"${basedn}\" \033[0m"

    basedn="BASE ${basedn}"
    sed -i "s/^#BASE.*/${basedn}/g" /etc/ldap/ldap.conf

    # set configuration password
    tmpfile="/tmp/tmp.ldif"
    if [ ! -z ${LDAP_CONFIG_PW+x} ]; then
        echo -e '\033[1;37;44m   ... set config password \033[0m'
        password_hash=$( slappasswd -s "${LDAP_CONFIG_PW}" )
        encode_pw=${password_hash//\//\\\/}

        slapcat -n0 -F "${slapd_base_path}" -l ${tmpfile}
        sed -i "s/\(olcRootDN: cn=admin,cn=config\)/\1\nolcRootPW: ${encode_pw}/g" ${tmpfile}
        rm -rf "${slapd_base_path}"/*
        slapadd -n0 -F "${slapd_base_path}" -l ${tmpfile}
        rm -f ${tmpfile}
    fi

    # register schemas
    if [ ! -z ${ADDITIONAL_SCHEMAS+x} ]; then
        echo -e '\033[1;37;44m   ... register additional schemas \033[0m'
        IFS=","; declare -a schemas=($ADDITIONAL_SCHEMAS); unset IFS

        for schema in "${schemas[@]}"; do
            slapadd -n0 -F "${slapd_base_path}" -l "/etc/ldap/schema/${schema}.ldif"
        done
    fi

    # register modules
    if [ ! -z ${ADDITIONAL_MODULES+x} ]; then
        echo -e '\033[1;37;44m   ... register additional modules \033[0m'
        IFS=","; declare -a modules=($ADDITIONAL_MODULES); unset IFS

        for module in "${modules[@]}"; do
            mfile="/etc/ldap/modules/${module}.ldif"

            if [ "$module" == 'ppolicy' ]; then
                PPOLICY_DN_PREFIX="${PPOLICY_DN_PREFIX:-cn=default,ou=policies}"

                sed -i "s/\(olcPPolicyDefault: \)PPOLICY_DN/\1${PPOLICY_DN_PREFIX}$dc_string/g" ${mfile}
            fi

            slapadd -n0 -F "${slapd_base_path}" -l "${mfile}"
        done
    fi

else
    echo -e "\033[1;42;97m Already configured – nothing to do. \033[0m"
fi

###
## define services to listen
###

# socket file
LDAP_SERVICES="ldapi:///"

# ldap without TLS
if [ ${#LDAP_PORT} -gt 0 ]; then
    echo -e "\033[1;42;97m Configured to listen on port ${LDAP_PORT} for LDAP ... \033[0m"
    LDAP_SERVICES="${LDAP_SERVICES} ldap://*:${LDAP_PORT}"
fi

# ldaps with TLS
if [ ${#LDAPS_PORT} -gt 0 ]; then
    if [ -z "${TLS_CERT_FILENAME}" ] || [ -z "${TLS_KEY_FILENAME}" ] || [ -z "${TLS_CA_FILENAME}" ]; then
        tls_filecheck="noTLS"
    else
        if [ ! -f "${TLS_CERTPATH}/${TLS_CERT_FILENAME}" ]; then
            tls_filecheck="noTLS"
            echo -e "\033[1;90;46m TLS cert file missing at ${TLS_CERTPATH}/${TLS_CERT_FILENAME} \033[0m"
        fi
        if [ ! -f "${TLS_CERTPATH}/${TLS_KEY_FILENAME}" ]; then
            tls_filecheck="noTLS"
            echo -e "\033[1;90;46m TLS key file missing at ${TLS_CERTPATH}/${TLS_KEY_FILENAME} \033[0m"
        fi
        if [ ! -f "${TLS_CERTPATH}/${TLS_CA_FILENAME}" ] ; then
            tls_filecheck="noTLS"
            echo -e "\033[1;90;46m TLS ca cert file missing at ${TLS_CERTPATH}/${TLS_CA_FILENAME} \033[0m"
        fi
    fi
    if [ ! -z ${tls_filecheck+x} ] && [ "${tls_filecheck}" == "noTLS" ]; then
        echo -e "\033[1;30;41m Parameters told to listen on port ${LDAPS_PORT} for LDAPS but TLS certificate files are not altogether ... \033[0m"
    else
        echo -e "\033[1;42;97m Configured to listen on port ${LDAPS_PORT} for LDAPS ... \033[0m"
        LDAP_SERVICES="${LDAP_SERVICES} ldaps://*:${LDAPS_PORT}"
        j2 /templates/tls.ldif.j2 -o "${TLS_LDIF_FILE}"
    fi
fi

export LDAP_SERVICES
echo -e "\033[1;42;97m Configured to listen via those services: ${LDAP_SERVICES} \033[0m"

# Set rights before startup
echo -e '\033[1;42;97m Change file ownership so LDAP user can work with them \033[0m'
chown -R ${LDAP_USER}:${LDAP_GROUP} /var/lib/ldap "${slapd_base_path}" &

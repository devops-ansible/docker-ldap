#!/usr/bin/env bash

export LDAP_USER="${LDAP_USER:-openldap}"
export LDAP_GROUP="${LDAP_GROUP:-openldap}"
export LDAP_PORT="${LDAP_PORT:-389}"
export LDAPS_PORT="${LDAPS_PORT:-}"

export IMPORT_DIR="${IMPORT_DIR:-/import/}"
export IMPORT_CONFIG_FILE="${IMPORT_CONFIG_FILE:-config.ldif}"
export IMPORT_DATA_FILE="${IMPORT_DATA_FILE:-data.ldif}"

export LOG_LEVEL="${LOG_LEVEL:-16384}"
export DATE_FORMAT="${DATE_FORMAT:-+%Y%m%d-%H%M%S}"

export FORCE_RECONFIGURE="${FORCE_RECONFIGURE:-false}"
export LDAP_BACKEND=${LDAP_BACKEND:-MDB}

config_db=${IMPORT_DIR}${IMPORT_CONFIG_FILE}
data_db=${IMPORT_DIR}${IMPORT_DATA_FILE}

# import config
if [ -e ${config_db} ]; then
    echo -en '   ... import config db'
    # clean up existing config
    rm -rf /etc/ldap/slapd.d/* /var/lib/ldap/*
    # import config
    slapadd -F /etc/ldap/slapd.d -n 0 -l ${config_db}
    # mark the config import file as imported
    mv ${config_db} ${config_db}.$(date ${DATE_FORMAT})
    echo ' ... done'
    initial_run=false
fi

# import data
if [ -e ${data_db} ]; then
    echo -en '   ... import data db'
    # clean up existing data
    rm -rf /var/lib/ldap/*
    # import data
    slapadd -F /etc/ldap/slapd.d -n 1 -l ${data_db}
    # mark the data import file as imported
    mv ${data_db} ${data_db}.$(date ${DATE_FORMAT})
    echo ' ... done'
    initial_run=false
fi

# configure slapd
if [ ! "$(ls -A /etc/ldap/slapd.d)" ] || [[ "${FORCE_RECONFIGURE}" == "true" ]]; then

    # check if we could continue with initiation

    break=false
    if [ -z ${LDAP_ADMIN_PW+x} ]; then
        echo -e "\e[1;41;30m ERROR: \e[0m ENV variable \e[1;42;33m LDAP_ADMIN_PW \e[0m not set, so we cannot initialize the LDAP."
        break=true
    fi
    if [ -z ${LDAP_DOMAIN+x} ]; then
        echo -e "\e[1;41;30m ERROR: \e[0m ENV variable \e[1;42;33m LDAP_DOMAIN \e[0m not set, so we cannot initialize the LDAP."
        break=true
    fi
    if [[ "${break}" == "true" ]]; then
        exit 1
    fi

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
    if [ -n ${LDAP_BASEDN+x} ]; then
        basedn="${LDAP_BASEDN}"
    else
        dc=""
        IFS="."; declare -a dc_elements=($LDAP_DOMAIN); unset IFS
        for dc_e in "${dc_elements[@]}"; do
            dc="${dc},dc=${dc_e}"
        done
    fi
    basedn="BASE ${dc:1}"
    sed -i "s/^#BASE.*/${basedn}/g" /etc/ldap/ldap.conf

    # set configuration password
    tmpfile="/tmp/tmp.ldif"
    if [ -n ${LDAP_CONFIG_PW+x} ]; then
        password_hash=`slappasswd -s "${LDAP_CONFIG_PW}"`
        encode_pw=${password_hash//\//\\\/}

        slapcat -n0 -F /etc/ldap/slapd.d -l ${tmpfile}
        sed -i "s/\(olcRootDN: cn=admin,cn=config\)/\1\nolcRootPW: ${encode_pw}/g" ${tmpfile}
        rm -rf /etc/ldap/slapd.d/*
        slapadd -n0 -F /etc/ldap/slapd.d -l ${tmpfile}
        rm -f ${tmpfile}
    fi

    # register schemas
    if [ -n ${ADDITIONAL_SCHEMAS+x} ]; then
        IFS=","; declare -a schemas=($ADDITIONAL_SCHEMAS); unset IFS

        for schema in "${schemas[@]}"; do
            slapadd -n0 -F /etc/ldap/slapd.d -l "/etc/ldap/schema/${schema}.ldif"
        done
    fi

    # register modules
    if [ -n ${ADDITIONAL_MODULES+x} ]; then
        IFS=","; declare -a modules=($ADDITIONAL_MODULES); unset IFS

        for module in "${modules[@]}"; do
             mfile="/etc/ldap/modules/${module}.ldif"

             if [ "$module" == 'ppolicy' ]; then
                 PPOLICY_DN_PREFIX="${PPOLICY_DN_PREFIX:-cn=default,ou=policies}"

                 sed -i "s/\(olcPPolicyDefault: \)PPOLICY_DN/\1${PPOLICY_DN_PREFIX}$dc_string/g" ${mfile}
             fi

             slapadd -n0 -F /etc/ldap/slapd.d -l "${mfile}"
        done
    fi

else
    echo -e "\e[1;42;97m Already configured ??? nothing to do. \e[0m"
fi

# set services
LDAP_SERVICES="ldapi:///"
if [ ${#LDAPS_PORT} -gt 0 ]; then
    echo "LDAPS: (${#LDAPS_PORT}) \"${LDAPS_PORT}\""
    LDAP_SERVICES="${LDAP_SERVICES} ldaps://*:${LDAPS_PORT}/"
fi
if [ ${#LDAP_PORT} -gt 0 ]; then
    echo "LDAP:  \"${LDAP_PORT}\""
    LDAP_SERVICES="${LDAP_SERVICES} ldap://*:${LDAP_PORT}/"
fi
export LDAP_SERVICES

# Set rights before startup
chown -R ${LDAP_USER}:${LDAP_GROUP} /var/lib/ldap /etc/ldap/slapd.d

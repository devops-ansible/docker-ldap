#!/usr/bin/env bash

###
## run a basic functionality test for LDAP
###
basicTest() {
    adminPW="Admin123"
    confPW="Config123"
    url="example.com"
    baseDN="dc=example,dc=com"
    setupLdapEnv "${adminPW}" "${confPW}" "${url}"
    ldapsearch -x -b "${baseDN}" -D "cn=admin,${baseDN}" -w "${adminPW}"
    stopLdap
}

###
## create an example SSL certificate with the Let's Encrypt staging service
###
legoTest() {
    testLegoChallenge
    tree "${LEGO_PATH}"
}

###
## run LDAP with Let's Encrypt certificate
###
ldapLE() {
    testLegoChallenge
    adminPW="Admin123"
    confPW="Config123"
    url="example.com"
    baseDN="dc=example,dc=com"
    ldapServer="$( lego_challenge primary | sed 's/^\*\./ldap\./g' )"
    cat <<EOF > /etc/hosts
# for testing purpose
127.0.0.1   ${ldapServer}
EOF
    export LDAPS_PORT=636
    setupLdapEnv "${adminPW}" "${confPW}" "${url}"
    ldapsearch -x     -b "${baseDN}" -D "cn=admin,${baseDN}" -w "${adminPW}" -H "ldaps://${ldapServer}:636"
    unset LDAPS_PORT
    stopLdap
}

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
    json="$( echo "${LEGO_TEST_CONFIG}" | base64 --decode )"
    for env_var in $( echo $json | jq -r 'to_entries | map( "\( .key )=\( .value | tostring )" ) | .[]' ); do
        export $env_var
    done
    lego_challenge test > /dev/null 2>&1
    tree "${LEGO_PATH}"
    for key in $( echo "${json}"| jq -r 'keys[]' ); do
        unset $key
    done
}

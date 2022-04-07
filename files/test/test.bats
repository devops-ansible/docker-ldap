#!/usr/bin/env bats

export TESTRUN="running"

setup() {
    echo -e '\033[1;90;106m loading bats helpers ... \033[0m'
    # load helpers
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}

teardown() {
    # clean up config and data
    stopLdap
    echo -e '\033[1;90;106m Cleaning up LDAP data ... \033[0m'
    cd /
    rm -rf /etc/ldap/slapd.d \
           /var/lib/ldap
    mkdir -p /etc/ldap/slapd.d \
           /var/lib/ldap
    cd /etc/ldap/slapd.d
}

setupLdapEnv() {
    export LDAP_ADMIN_PW="${1}"
    export LDAP_CONFIG_PW="${2}"
    export LDAP_DOMAIN="${3}"
    startLdap
}

startLdap() {
    echo -e '\033[1;90;106m Starting LDAP service by running entrypoint ... \033[0m'
    entrypoint start &
    fullWait=10
    sec=${fullWait}
    while [ ${sec} -ge 0 ]; do
        echo -ne "\033[1;90;106m Waiting for ${fullWait} seconds (${sec}) ... \033[0m\033[0K\r"
        sleep 1 3>-
        let "sec=sec-1"
    done
    echo -e "\033[1;90;106m Waited ${fullWait} seconds for LDAP startup. \033[0m"
}

stopLdap() {
    echo -e "\033[1;90;106m Stopping LDAP service. \033[0m"
    pid="$( pgrep slapd )"
    if [ "$?" -eq 0 ]; then
        kill ${pid}
    fi
}

basicTest() {
    adminPW="Admin123"
    confPW="Config123"
    url="example.com"
    baseDN="dc=example,dc=com"
    setupLdapEnv "${adminPW}" "${confPW}" "${url}"
    ldapsearch -x -b "${baseDN}" -D "cn=admin,${baseDN}" -w "${adminPW}"
    stopLdap
}

@test "basic search succeeds" {
    run basicTest
    echo "status:\n${status}"
    echo -e "output:\n${output}"
    [ "${status}" -eq 0 ]
    assert_output --partial 'result: 0 Success'
    assert_output --partial '# numResponses: 3'
    assert_output --partial '# numEntries: 2'
}

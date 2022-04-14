#!/usr/bin/env bash

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
    maxWait=90 # wait a maximum of 15 minutes
    runLoop=true
    while [ "${runLoop}" == true ]; do
        sec=${fullWait}
        while [ ${sec} -ge 0 ]; do
            echo -ne "\033[1;90;106m Waiting for ${fullWait} seconds (${sec}) ... \033[0m\033[0K\r"
            sleep 1 3>-
            let "sec=sec-1"
        done
        let "maxWait=maxWait-1"
        _slapdPid
        if [ "$?" -eq 0 ]; then
            runLoop=false
        elif [ "${maxWait}" -eq 0 ]; then
            runLoop=false
            echo -e "\033[1;30;41m Timeout waiting for \`slapd\` starting up ... \033[0m"
            return 1
        else
            echo -e "\033[1;39;43m Waiting for another ${fullWait} seconds ... \033[0m"
        fi
    done
    echo -e "\033[1;90;106m Waited ${fullWait} seconds for LDAP startup. \033[0m"
}

stopLdap() {
    echo -e "\033[1;90;106m Stopping entrypoint and so slapd service. \033[0m"
    # `ps -ef` returns list of all processes running – with those columns:
    # UID PID PPID C STIME TTY TIME CMD
    # `awk` checks `CMD` is `entrypoint start`. Assuming there `entrypoint start` did only run once.
    pidv="$( ps -ef | awk '{if ( $9 ~ "entrypoint" && $10 == "start" ) print $2}' )"
    if [ "$?" -eq 0 ]; then
        kill ${pidv}
    fi
}

getLegoTestConfigJson() {
    echo ${LEGO_TEST_CONFIG} | base64 --decode | j2 /dev/stdin
}

testLegoChallenge() {
    json="$( getLegoTestConfigJson )"
    for env_var in $( echo $json | jq -r 'to_entries | map( "\( .key )=\( .value | tostring )" ) | .[]' ); do
        export $env_var
    done
    lego_challenge test > /dev/null 2>&1
}

clearLegoEnv() {
    json="$( getLegoTestConfigJson )"
    for key in $( echo "${json}"| jq -r 'keys[]' ); do
        unset $key
    done
}

teardownLego() {
    rm -rf "${LEGO_PATH:-/lego}"
    clearLegoEnv
}

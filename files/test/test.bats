#!/usr/bin/env bats

export TESTRUN="running"

load _general
load _testFunctions

@test "basic search succeeds" {
    run basicTest
    [ "${status}" -eq 0 ]
    assert_output --partial 'result: 0 Success'
    assert_output --partial '# numResponses: 3'
    assert_output --partial '# numEntries: 2'
}

@test "LEGO certs creation basic test" {
    run legoTest
    [ "${status}" -eq 0 ]
    assert_output --partial "$( echo "${LEGO_CERT_DOMAIN}" | sed 's/^\*/\_/g' ).crt"
    assert_output --partial "$( echo "${LEGO_CERT_DOMAIN}" | sed 's/^\*/\_/g' ).key"
    run teardownLego
}

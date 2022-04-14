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

@test "TLS test with Let's Encrypt and LEGO" {
    run legoTest
    [ "${status}" -eq 0 ]
    assert_output --partial "$( lego_challenge certname ).crt"
    assert_output --partial "$( lego_challenge certname ).key"

    run ldapLE
    [ "${status}" -eq 0 ]
    assert_output --partial 'result: 0 Success'
    assert_output --partial '# numResponses: 3'
    assert_output --partial '# numEntries: 2'
    run teardownLego
}

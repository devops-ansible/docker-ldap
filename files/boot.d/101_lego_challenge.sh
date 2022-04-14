#!/usr/bin/env bash

set +e

if [ ! -z ${TESTRUN+x} ] && [ "${TESTRUN}" == "running" ]; then
    lego_challenge test
    rc="$?"
else
    lego_challenge
    rc="$?"
fi

set -e

if [ "${rc}" -eq 0 ]; then
    export TLS_CERTPATH="${LEGO_PATH}/certificates"
    certFileName="$( lego_challenge certname )"
    export TLS_CERT_FILENAME="${certFileName}.crt"
    export TLS_KEY_FILENAME="${certFileName}.key"
    export TLS_CA_FILENAME="${certFileName}.issuer.crt"
fi

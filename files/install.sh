#!/usr/bin/env bash

set -e

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${SCRIPT_PATH}

apt-get update -q --fix-missing
apt-get install -yq --no-install-recommends \
    libsasl2-modules libsasl2-modules-db libsasl2-modules-gssapi-mit libsasl2-modules-ldap libsasl2-modules-otp libsasl2-modules-sql \
    slapd slapd-contrib \
    ldap-utils \
    krb5-kdc-ldap \
    db-util \
    lego

pip install j2cli

export BUILD_ARG_TESTING="$( echo "${BUILD_ARG_TESTING}" | tr '[:upper:]' '[:lower:]' )"

cpwd="$( pwd )"
cd templates/
j2 ./entrypoint.j2 -o "${cpwd}/bin/entrypoint"
cd "${cpwd}"

chmod a+x bin/*

mv boot.d/* /boot.d/
mv bin/*    /usr/local/bin/

if [ "${BUILD_ARG_TESTING}" = "true" ] || [ "${BUILD_ARG_TESTING}" = "yes" ]; then
    # testing cases are requested, so keep them
    mv ./test /ldap_testing
    # initiate BATS by fetching the resources
    git clone https://github.com/bats-core/bats-core.git    "${TESTS_PATH}/bats"
    git clone https://github.com/bats-core/bats-support.git "${TESTS_PATH}/test_helper/bats-support"
    git clone https://github.com/bats-core/bats-assert.git  "${TESTS_PATH}/test_helper/bats-assert"
else
    # BATS is not initiated, so we should not extend the system PATH variable
    rm -f /boot.d/*_bats_*.sh
fi

# perform installation cleanup
apt-get -y clean
apt-get -y autoclean
apt-get -y autoremove
rm -rf /var/lib/apt/lists/*

rm -rf /etc/ldap/slapd.d/*

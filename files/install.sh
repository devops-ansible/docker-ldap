#!/usr/bin/env bash

set -e

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${SCRIPT_PATH}

mv boot.d/*   /boot.d/
mv entrypoint /usr/local/bin/

apt-get update -q --fix-missing
apt-get install -yq --no-install-recommends \
    libsasl2-modules libsasl2-modules-db libsasl2-modules-gssapi-mit libsasl2-modules-ldap libsasl2-modules-otp libsasl2-modules-sql \
    slapd slapd-contrib \
    ldap-utils \
    krb5-kdc-ldap \
    db-util \
    lego

pip install j2cli

BUILD_ARG_TESTING=$( echo "${BUILD_ARG_TESTING}" | tr '[:upper:]' '[:lower:]' )
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

cat <<'EOF' > /usr/local/bin/start_slapd
#!/usr/bin/env bash

# do the regular LDAP startup in foreground for docker container
# to stay alive – for that, the loglevel has to be defined.

/usr/sbin/slapd -h "${LDAP_SERVICES}" \
                -g "${LDAP_GROUP}" \
                -u "${LDAP_USER}" \
                -F "/etc/ldap/slapd.d" \
                -d "${LDAP_LOGLEVEL}"
EOF

cat <<'EOF' > /usr/local/bin/_slapdPid
#!/usr/bin/env bash

slapdPid="$( pgrep slapd )"
if [ "$?" -eq 0 ]; then
    echo "${slapdPid}"
else
    exit 1
fi
EOF

cat <<'EOF' > /usr/local/bin/_termSlapd
#!/usr/bin/env bash

# `_slapdPid` may return another rc then 0
# but we don't want to break here ...
set +e

# retrieve actual PID of slapd running
slapdPid="$( _slapdPid )"
if [ "$?" -eq 0 ]; then

    # clean termination of slapd
    kill -TERM "${slapdPid}" 2&> /dev/null

    # wait until slapd has ended
    _slapdPid 1&> /dev/null
    while [ "$?" == 0 ]; do
        _slapdPid 1&> /dev/null
    done
fi
exit 0
EOF

chmod a+x /usr/local/bin/entrypoint \
          /usr/local/bin/start_slapd \
          /usr/local/bin/_slapdPid \
          /usr/local/bin/_termSlapd

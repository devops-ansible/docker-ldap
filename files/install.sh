#!/usr/bin/env bash

# Break installation of Docker image when an error occurs
set -e

# Get path of installation script and change dir there
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd "${SCRIPT_PATH}"

# Install missing tools for this Docker image
apt-get update -q --fix-missing
apt-get install -yq --no-install-recommends \
    libsasl2-modules libsasl2-modules-db libsasl2-modules-gssapi-mit libsasl2-modules-ldap libsasl2-modules-otp libsasl2-modules-sql \
    slapd slapd-contrib \
    ldap-utils \
    krb5-kdc-ldap \
    db-util \
    dnsutils

# gather, download and install newest GO version
GO_URL="https://go.dev/dl/"
GO_VERSION=$(curl -s "${GO_URL}" | grep 'download.*downloadBox' | head -n 1 | sed -nE 's/^.*(go[0-9]+\.[0-9]+\.[0-9]+).*$/\1/p' )
GO_FILENAME="${GO_VERSION}.linux-$( dpkg --print-architecture ).tar.gz"
curl -LO "${GO_URL}${GO_FILENAME}"
tar -C "${SCRIPT_PATH}" -xzf "${GO_FILENAME}"
export GOROOT="${SCRIPT_PATH}/go"
export PATH="${GOROOT}/bin:${PATH}"

# install LEGO from source since bundled version is pretty old ...
git clone https://github.com/go-acme/lego.git
cd lego
# checkout last release tag
git checkout $( git tag -l | sort -V | tail -n 1 )
# build latest `lego` version binary
make build
# place it as executable
mv ./dist/lego /usr/local/bin/
# clean up caches
go clean -modcache
cd "${SCRIPT_PATH}"

# Since we work with templates, Jinja2 CLI should be present within the image
pip install j2cli

# Is a testing image being built?
export BUILD_ARG_TESTING="$( echo "${BUILD_ARG_TESTING}" | tr '[:upper:]' '[:lower:]' )"

# Build entrypoint script from (nested) Jinja2 templates.
export J2T_PATH="$( pwd )/templates/"
j2 ./templates/entrypoint.j2 -o ./bin/entrypoint

# Make all bins executable – also the currently created `entrypoint`
chmod a+x bin/*

# Move files from install dir where they belong
mv boot.d/*        /boot.d/
mv bin/*           /usr/local/bin/
mv templates/final /templates

# Prepare testing if is being built with tests enabled
if [ "${BUILD_ARG_TESTING}" = "true" ] || [ "${BUILD_ARG_TESTING}" = "yes" ]; then
    # Testing cases are requested, so move them to persistent path
    mv ./test "${TESTS_PATH}"
    # Initiate BATS by fetching the resources
    git clone https://github.com/bats-core/bats-core.git    "${TESTS_PATH}/bats"
    git clone https://github.com/bats-core/bats-support.git "${TESTS_PATH}/test_helper/bats-support"
    git clone https://github.com/bats-core/bats-assert.git  "${TESTS_PATH}/test_helper/bats-assert"
    # Download LE staging CA for testing purposes
    certsdir="${CUSTOM_CERTS_PATH:-/certs}"
    mkdir -p "${certsdir}" && cd "${certsdir}" && { curl -O https://letsencrypt.org/certs/staging/letsencrypt-stg-root-x1.pem ; curl -O https://letsencrypt.org/certs/staging/letsencrypt-stg-root-x2.pem ; cd -; }
    source /boot.d/base.custom_certs.sh
else
    # BATS is not initiated, so we should not extend the system PATH variable
    rm -f /boot.d/*_bats_*.sh
fi

# Perform installation cleanup
apt-get -y clean
apt-get -y autoclean
apt-get -y autoremove
rm -rf /var/lib/apt/lists/*

# Ensure the slapd library to be empty
rm -rf /etc/ldap/slapd.d/*

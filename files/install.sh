#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd ${SCRIPT_PATH}

mv boot.d/* /boot.d/

chmod a+x entrypoint
mv entrypoint /usr/local/bin/

mv templates /

apt-get update -q --fix-missing
apt-get install -yq --no-install-recommends \
    slapd \
    ldap-utils \
    db-util

pip install j2cli

# perform installation cleanup
apt-get -y clean
apt-get -y autoclean
apt-get -y autoremove
rm -rf /var/lib/apt/lists/*

rm -rf /etc/ldap/slapd.d/*

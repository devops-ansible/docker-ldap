#!/usr/bin/env bash

basicTest() {
    adminPW="Admin123"
    confPW="Config123"
    url="example.com"
    baseDN="dc=example,dc=com"
    setupLdapEnv "${adminPW}" "${confPW}" "${url}"
    ldapsearch -x -b "${baseDN}" -D "cn=admin,${baseDN}" -w "${adminPW}"
    stopLdap
}

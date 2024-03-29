ARG BASE_IMAGE=devopsansiblede/baseimage
ARG BASE_VERSION=latest

FROM ${BASE_IMAGE}:${BASE_VERSION}

MAINTAINER macwinnie <dev@macwinnie.me>

# VOLUME  /etc/ldap/slapd.d   /var/lib/ldap   /lego
WORKDIR /etc/ldap/slapd.d

ARG INSTALLDIR="/usr/src/install"
ARG BUILD_ARG_TESTING="no"

ENV TESTS_PATH         "/ldap_testing"

ENV LDAP_USER          "openldap"
ENV LDAP_GROUP         "openldap"
ENV LDAP_PORT          "389"
ENV LDAPS_PORT         ""
ENV LDAP_DOMAIN        "example.com"
ENV LDAP_BACKEND       "MDB"
ENV LDAP_LOGLEVEL      "16384"
ENV LDAP_ULIMIT        "1024"

ENV IMPORT_DIR         "/import/"
ENV IMPORT_CONFIG_FILE "config.ldif"
ENV IMPORT_DATA_FILE   "data.ldif"

ENV DATE_FORMAT        "+%Y%m%d-%H%M%S"
ENV RUNNING_CHECK      "30"

ENV FORCE_RECONFIGURE  "false"

ENV LEGO_PATH          "/lego"
ENV LEGO_DNS_RESOLVERS "208.67.222.222:53"
ENV TLS_CERTPATH       "/etc/ssl/certificates"

COPY files/ ${INSTALLDIR}/

RUN  chmod +x ${INSTALLDIR}/install.sh && \
     ${INSTALLDIR}/install.sh && \
     rm -rf ${INSTALLDIR}

ENTRYPOINT [ "entrypoint"]
CMD [ "start" ]

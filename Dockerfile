ARG IMAGE=devopsansiblede/baseimage
ARG VERSION=latest

FROM ${IMAGE}:${VERSION}

MAINTAINER macwinnie <dev@macwinnie.me>

ENV LDAP_USER          "openldap"
ENV LDAP_GROUP         "openldap"
ENV LDAP_PORT          "389"
ENV LDAPS_PORT         ""
ENV LDAP_DOMAIN        "example.com"

ENV IMPORT_DIR         "/import/"
ENV IMPORT_CONFIG_FILE "config.ldif"
ENV IMPORT_DATA_FILE   "data.ldif"

ENV LDAP_BACKEND       "MDB"
ENV LDAP_LOGLEVEL      "16384"
ENV DATE_FORMAT        "+%Y%m%d-%H%M%S"

ENV FORCE_RECONFIGURE  "false"

ARG INSTALLDIR="/usr/src/install"

COPY    files/ ${INSTALLDIR}/
WORKDIR        ${INSTALLDIR}

RUN chmod +x ./install.sh && \
    ./install.sh && \
    rm -rf ${INSTALLDIR}

WORKDIR /etc/ldap/slapd.d

ENTRYPOINT [ "entrypoint"]
CMD [ "start" ]

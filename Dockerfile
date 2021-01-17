FROM devopsansiblede/baseimage:latest

MAINTAINER macwinnie <dev@macwinnie.me>

ENV REFRESHED_AT 2021-01-16

COPY files/ /DockerInstall/

RUN chmod +x /DockerInstall/install.sh && \
    /DockerInstall/install.sh

WORKDIR /etc/ldap/slapd.d

ENTRYPOINT [ "entrypoint"]
# we need `sh` since environmental variables are only evaluated within a shell in Docker ...
CMD [ "sh", "-c", "/usr/sbin/slapd -h \"${LDAP_SERVICES}\" -g \"${LDAP_GROUP}\" -u \"${LDAP_USER}\" -F \"/etc/ldap/slapd.d\" -d \"${LOG_LEVEL}\"" ]

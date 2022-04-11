# OpenLDAP

OpenLDAP Server based on [devopsansiblede/baseimage](https://github.com/devops-ansible/docker-base). Supports data loading via volume mount as well as SSL based LDAP (ldaps).

## ENV Variables

| env                   | default               | change recommended | description |
| --------------------- | --------------------- |:------------------:| ----------- |
| `LDAP_PORT`           | `389`                 | yes                | port for LDAP to listen – unencrypted |
| `LDAPS_PORT`          |                       | yes                | port for LDAP to listen – SSL encrypted; not to be confused with STARTLS |
| `LDAP_LOGLEVEL`       | `16384`               | no                 | log level for the slapd; see [table 5.1 in OpenLDAP documentation](https://www.openldap.org/doc/admin24/slapdconf2.html#olcLogLevel:%20%3Clevel%3E) |
| `IMPORT_DIR`          | `"/import/"`          | no                 ||
| `IMPORT_CONFIG_FILE`  | `"config.ldif"`       | no                 ||
| `IMPORT_DATA_FILE`    | `"data.ldif"`         | no                 ||
| `LDAP_ADMIN_PW`       | **mandatory** when initiating db | yes     | plain text password for admin user |
| `LDAP_CONFIG_PW`      | **mandatory** when initiating db | yes     | plain text password for configuration |
| `LDAP_DOMAIN`         | **mandatory** when initiating db | yes     ||
| `LDAP_BASEDN`         | DN derived from `LDAP_DOMAIN` | no         | you may define a custom BaseDN for your LDAP – but by default, it would be derived from `LDAP_DOMAIN` |
| `LDAP_ORGANISATION`   | `LDAP_DOMAIN`         | yes                | Organisation name of a new LDAP instance |
| `LDAP_BACKEND`        | `MDB`                 | no                 | Backend Type |
| `LDAP_ULIMIT`         | `1024`                | no                 | Reduce maximum number of number of open file descriptors to 1024, see [Bug report](https://github.com/docker/docker/issues/8231) |
| `ADDITIONAL_MODULES`  |                       | yes                | comma separated list of modules to be enabled |
| `ADDITIONAL_SCHEMAS`  |                       | yes                | comma separated list of schemas to be enabled |
| `TESTRUN`             |                       | no                 | for development purpose to start the container without running `/boot.sh` in entrypoint when starting with `bash` as `CMD` |
| `LEGO_ACCOUNT_EMAIL`  |                       | yes                |  |
| `LEGO_CERT_DOMAIN`    |                       | yes                |  |

**For the usage of LEGO DNS challenge, you'll have to use the environmental variables needed for your DNS provider. You can find that configuration [within LEGO documentation](https://go-acme.github.io/lego/dns/).**

This Docker image only supports DNS challenge, since ports 443 / 80 won't be exposed / published / used. We highly recommend to stay with DNS challenge.

### building and testing variables

Those variables are not recommended to be changed. They are only used while building / testing the docker image.

| variable name       | type  | value                       | description |
| ------------------- | ----- | --------------------------- | ----------- |
| `BASE_IMAGE`        | `ARG` | `devopsansiblede/baseimage` | base image from where to build the LDAP image |
| `BASE_VERSION`      | `ARG` | `latest`                    | version / tag of the base image which should be used for building the image |
| `INSTALLDIR`        | `ARG` | `/usr/src/install`          | path where to copy installation information while building image |
| `BUILD_ARG_TESTING` | `ARG` | `no`                        | set to `yes` by GitHub workflow to build testing image |
| `TESTS_PATH`        | `ENV` | `/ldap_testing`             | path where to find [BATS tests](https://bats-core.readthedocs.io/en/stable/tutorial.html) within testing image |

*By using the different types of environmental variables within the image build and usage process, we assure them being available in relevant contexts.  
Docker uses build arguments (type `ARG`) for environmental variables only available during the build process of an image. `ENV` type variables are available in both contexts, during the build and when running a container from the image.*

## Usage

### Container Parameters

Start a new openldap server instance, import config & data.ldif's from another instance and persist the state in _data_
```sh
docker run -d -p 389:127.0.0.1:389 -p 636:636 -v $PWD/data/database:/var/lib/ldap -v $PWD/data/config:/etc/ldap/slapd.d -v $PWD/import:/import --name ldap devopsansiblede/ldap:latest
```

### Volumes

* `/etc/ldap/slap.d` - Config database
* `/var/lib/ldap` - Data database

### Useful File Locations

* `/certs` - location for custom certificates
* `/import/config.ldif` - Text file containing the exported config tree _(`${IMPORT_DIR}${IMPORT_CONFIG_FILE}`)_
* `/import/data.ldif` - Text file containing the exported data tree _(`${IMPORT_DIR}${IMPORT_DATA_FILE}`)_
* `/etc/defaults/slapd` - Slapd startup configuration

## last built

0000-00-00 00:00:00

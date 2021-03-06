# OpenLDAP

OpenLDAP Server based on devopsansiblede/baseimage:latest. Supports data loading via volume mount as well as SSL based LDAP (ldaps).

## ENV Variables

| env                   | default               | change recommended | description |
| --------------------- | --------------------- |:------------------:| ----------- |
| `LDAP_PORT`           | `389`                 | yes                | port for LDAP to listen – unencrypted |
| `LDAPS_PORT`          |                       | yes                | port for LDAP to listen – SSL encrypted; not to be confused with STARTLS |
| `LOG_LEVEL`           | `16384`               | no                 | log level for the slapd |
| `IMPORT_DIR`          | `"/import/"`          | no                 ||
| `IMPORT_CONFIG_FILE`  | `"config.ldif"`       | no                 ||
| `IMPORT_DATA_FILE`    | `"data.ldif"`         | no                 ||
| `LDAP_ADMIN_PW`       | **mandatory** when initiating db | yes     | plain text password for admin user |
| `LDAP_CONFIG_PW`      | **mandatory** when initiating db | yes     | plain text password for configuration |
| `LDAP_DOMAIN`         | **mandatory** when initiating db | yes     ||
| `LDAP_BASEDN`         | DN derived from `LDAP_DOMAIN` | yes        ||
| `LDAP_ORGANISATION`   | 
| `LDAP_BACKEND`        | `MDB`                  | no                | Backend Type |
| `ADDITIONAL_MODULES`  |                        | yes               | comma separated list of modules to be enabled |
| `ADDITIONAL_SCHEMAS`  |                        | yes               | comma separated list of schemas to be enabled |

## Usage

### Container Parameters

Start a new openldap server instance, import config & data.ldif's from another instance and persist the state in _data_
```sh
docker run -d -p 389:389 -p 636:636 -v $PWD/data/database:/var/lib/ldap -v $PWD/data/config:/etc/ldap/slapd.d -v $PWD/import:/import --name ldap devopsansiblede/ldap:latest
```

### Volumes

* `/etc/ldap/slap.d` - Config database
* `/var/lib/ldap` - Data database

### Useful File Locations

* `/certs` - location for custom certificates
* `/import/config.ldif` - Text file containing the exported config tree _(`${IMPORT_DIR}${IMPORT_CONFIG_FILE}`)_
* `/import/data.ldif` - Text file containing the exported data tree _(`${IMPORT_DIR}${IMPORT_DATA_FILE}`)_
* `/etc/defaults/slapd` - Slapd startup configuration

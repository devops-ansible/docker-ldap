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
| `RUNNING_CHECK`       | `30`                  | no                 | all `x` seconds (value of this variable) the entrypoint run with CMD `start` will check if slapd still is running. |
| `LEGO_ACCOUNT_EMAIL`  |                       | yes                | your account email for certificate challenges |
| `LEGO_CERT_DOMAIN`    |                       | yes                | the domain (we recommend a wildcard, see below) the certificate should be challenged for. Either a single string `*.auth.example.com` or a JSON list like `[ "a.example.com", "b.example.com" ]` |
| `LEGO_DNS_PROVIDER`   |                       | yes                | your DNS provider – see [list of LEGO DNS providers](https://go-acme.github.io/lego/dns/#dns-providers) |
| `LEGO_RENEW_DAYS`     | `30`                  | yes                | number of days when the certificate has to be renewed |
| `LEGO_PATH`           | `/lego`               | no                 | absolute path where Lego account and created certificates live |
| `LEGO_DNS_RESOLVERS`  | `208.67.222.222:53`   | no                 | DNS resolver against which the LEGO challenge will check existence of verification DNS entries – defaults to OpenDNS primary server. *Override with empty string to use Docker host default and – in case that one does not respond – the LEGO fallback (aka Google DNS).* |
| `TLS_CERTPATH`        | `/etc/ssl/certificates` | no               | path for your custom TLS certificates (if not Let's Encrypt triggered by [LEGO](https://go-acme.github.io/lego)) |
| `TLS_CERT_FILENAME`   |                       | yes                | LDAP TLS certificate file name within `TLS_CERTPATH` – **use only if no Let's Encrypt should be triggered!** |
| `TLS_KEY_FILENAME`    |                       | yes                | LDAP TLS key file name belonging to `TLS_CERT_FILENAME` certificate within `TLS_CERTPATH` – **use only if no Let's Encrypt should be triggered!** |
| `TLS_CA_FILENAME`     |                       | yes                | CA certificate file name within `TLS_CERTPATH` – **use only if no Let's Encrypt should be triggered!** |

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

### LEGO for Let's Encrypt certificates

We built in [LEGO](https://go-acme.github.io/lego) to ease certificate management for your LDAP service.

While developing, we got into some thinking about what best practices we should suggest. There are a few.

* First, our main **convention** is that `devopsansiblede/ldap` image will only support DNS challenge for certificates. HTTP/S challenges won't be supported. Yes, that's a convention and not a recommendation – so you need to follow this one mandatorily.  
*If you need to use HTTP/S challenge or want to use another certificate generation tool (like ACME requests managed by [Træfik](https://doc.traefik.io/traefik/https/acme/) and the usage of [devopsansiblede/acme_certs_extract](https://github.com/devops-ansible/acme-certs-extract) Docker image to extract and copy the certificate files), you could add a listener on the docker host that will stop the services within the `devopsansiblede/ldap` container by executing `_termSlapd` command. That will cause a `slapd` restart within the set period of `RUNNING_CHECK` seconds.*
* We recommend you to use wildcard fqdns for requested `LEGO_CERT_DOMAIN`, e.g. `*.auth.example.com` where your ldap could be `ldap-master.auth.example.com`.  
*That is for all certificates being listed in [Certificate Search](https://crt.sh) service and anybody could retrieve FQDNs from there at no effort.*

### Container Parameters

Start a new openldap server instance, import config & data.ldif's from another instance and persist the state in `./data`:

```sh
docker run -d \
           -p 389:127.0.0.1:389 -p 636:636 \
           -v $( pwd )/data/database:/var/lib/ldap \
           -v $( pwd )/data/config:/etc/ldap/slapd.d \
           -v $( pwd )/import:/import \
           --name ldap \
       devopsansiblede/ldap:latest
```

_**We strongly recommend you not to publish the insecure port `389` – just don't use it when you can avoid. When you need to use it, please secure the connection in another way like building up a SSH tunnel**, e.g. by the command `ssh -L 389:172.17.0.3:389 ssh.host.example.com` where you bind your local port `389` to the remote port `389` of the Docker container with the IP `172.17.0.3` running on your remote server `ssh.host.example.com`._

### Volumes

* `/etc/ldap/slap.d` - Config database
* `/var/lib/ldap` - Data database
* `/lego` – The location where [LEGO](https://go-acme.github.io/lego) data lives, as your account for Let's Encrypt certificate creation, certificates, etc.

### Useful File Locations

* `/certs` - location for custom CA certificates that should be trusted
* `/etc/ssl/certificates` – the location where (by default) custom TLS certificates will be searched for
* `/import/config.ldif` - Text file containing the exported config tree _(`${IMPORT_DIR}${IMPORT_CONFIG_FILE}`)_
* `/import/data.ldif` - Text file containing the exported data tree _(`${IMPORT_DIR}${IMPORT_DATA_FILE}`)_
* `/etc/defaults/slapd` - Slapd startup configuration

## last built

2024-01-21 23:58:30

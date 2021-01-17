#!/usr/bin/env bash

###
## Import Custom Certificate
###

CertsFolder="/certs"

if [ -d "$CertsFolder" ] && [ "$(ls -A $CertsFolder)" ]; then

    echo "Now adding certificates from directory ${CertsFolder}"
    cd $CertsFolder

    for cert in $(find -name \*.crt -o -name \*.pem); do
        cert="${cert:2}"
        echo "... adding ${cert}"
        cp $CertsFolder/$cert /usr/share/ca-certificates
        chmod 0755 /usr/share/ca-certificates/$cert
        echo "$cert" >> /etc/ca-certificates.conf
    done

    update-ca-certificates

    echo '... done with certificates'
    echo
fi

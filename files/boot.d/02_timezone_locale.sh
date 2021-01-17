#!/usr/bin/env bash

###
## adjust timezone
###

echo "Now working on your timezone and define it to ${CUSTOM_TIMEZONE} ..."
timezone_file="/usr/share/zoneinfo/${CUSTOM_TIMEZONE}"
host_timezone="/etc/timezone"

if [ -e $timezone_file ]; then
    if [ -e $host_timezone ]; then
        echo "${CUSTOM_TIMEZONE}" > $host_timezone
    fi
    ln -sf "/usr/share/zoneinfo/${CUSTOM_TIMEZONE}" /etc/localtime
fi

###
## adjust LOCALE
###

# update-locale "LANG=${SET_LOCALE}"
export LC_ALL="${SET_LOCALE}"
export LANG="${SET_LOCALE}"
export LANGUAGE="${SET_LOCALE}"

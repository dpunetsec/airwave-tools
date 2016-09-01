#!/bin/sh

# API documentation:
#   https://airwave.example.net/api

# uncomment for debugging
#set -x

# it wants username/password creds, use curl -d @file option, better than cli
AW_LOGIN=~/.airwave_login

# touched files under this directory corresponds to XML API calls we make
APIDIR=~/etc/airwave/api-enabled

# base directory where we store data
DATADIR=~/data/airwave

# this api sucks, act as a client browser, caching a cookie and a custom header
AW_HEADER=${DATADIR}/.airwave_header
AW_COOKIE=${DATADIR}/.airwave_cookie

# our api calls begin here
BASE_URL=https://airwave.example.net

# if something goes belly up, bail with a msg to stderr
fatal() {
    echo ${1:-unknown fatal error} >&2
    exit 1
}

# make sure our environment is good to go
if test ! -r ${AW_LOGIN}
then
    error "${AW_LOGIN} credentials file not readable"
fi
if test ! -d ${DATADIR}
then
    mkdir -p ${DATADIR} || error "failed mkdir ${DATADIR}"
fi
if test ! -d ${APIDIR}
then
    error "api-enabled directory ${APIDIR} not available"
fi

# curl arguments and options we may use:
#   -b file           load cookie from file
#   -c file           store cookie to file
#   -d @file          read post parameters from file
#   -D file           store response header to file
#   -o file           store content to file
#   -s                silent output
#   --create-dirs     create directories if necessary to save output files
#   --header string   set request header field to value in string

# perform the initial authentication
_url=${BASE_URL}/LOGIN
curl -s -c ${AW_COOKIE} -D ${AW_HEADER} -d @${AW_LOGIN} $_url -o /dev/null
if [ $? -ne 0 ]
then
    fatal "curl login failure"
fi

# AirWave client API will need this header after initial authentication
_biscotti=`grep -m1 X-BISCOTTI: ${AW_HEADER}`
if test -z "$_biscotti"
then
    fatal "missing BISCOTTI header field"
fi

# remove leading path to the enabled apis, get all enabled api file paths
for each in `find ${APIDIR} -type f | sed -e "s|${APIDIR}/*||" -e '/^\s*$/d'`
do
    _url=${BASE_URL}/$each.xml

    curl -s -b ${AW_COOKIE} --header "${BISCOTTI}" $_url --create-dirs -o ${DATADIR}/$each.xml
    if [ $? -ne 0 ]
    then
        fatal "curl download failure"
    fi
done

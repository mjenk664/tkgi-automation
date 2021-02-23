#!/bin/bash

source bosh_env

# login to the BOSH director Credhub using info from bbl
echo "Connecting to Credhub on BOSH Director...."
credhub login

# figure out the path for the vars we want
# (this depends on what we used as our BBL_ENVIRONMENT_NAME)
SECRET_PATH=$(credhub find -n concourse_to_credhub_secret | grep name | awk '{print $NF}')
CA_PATH=$(credhub find -n atc_tls | grep name | awk '{print $NF}')

# read the CA certificate and client secret from the BOSH director's Credhub
echo "Reading environment details from Credhub on BOSH Director...."
SECRET=$(credhub get -n $SECRET_PATH | grep value | awk '{print $NF}')
CERT=$(credhub get -n $CA_PATH -k certificate)
# CERT=$(cat atc_ca_cert.pem)

export CONCOURSE_URL="https://concourse.url.com"

# reset Credhub environment variables to point at the Concourse Credhub
unset CREDHUB_PROXY
export CREDHUB_SERVER="$CONCOURSE_URL:8844"
export CREDHUB_CLIENT=concourse_to_credhub
export CREDHUB_SECRET=$SECRET
export CREDHUB_CA_CERT=$CERT

echo "Connecting to Concourse Credhub..."
credhub login
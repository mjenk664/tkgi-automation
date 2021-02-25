#!/bin/bash

set -eu

if [ -z "${DEPLOYMENT_NAME}" ]; then
  { printf "\nError: 'DEPLOYMENT_NAME' parameter is required"; } 2>/dev/null
  exit 1
fi

# shellcheck source=./setup-bosh-env.sh
source ./config/tasks/setup-bosh-env.sh

set -x

pushd backup
  bbr deployment \
      --deployment "${DEPLOYMENT_NAME}" \
    backup-cleanup

  bbr deployment \
      --deployment "${DEPLOYMENT_NAME}" \
    backup --with-manifest

  tar -zcvf product_"${DEPLOYMENT_NAME}"_"$( date +"%Y-%m-%d-%H-%M-%S" )".tgz --remove-files -- */*
popd
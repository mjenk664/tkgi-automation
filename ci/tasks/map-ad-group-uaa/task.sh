#!/bin/bash

# Login to UAA
uaac target "${UAA_TARGET}" --skip-ssl-validation

# Get Bearer Token
uaac token client get "${UAA_ADMIN_CLIENT_ID}" -s "${UAA_ADMIN_CLIENT_SECRET}"

# Check if group is already mapped
CHECK_AD_GROUP=$(uaac group mappings | grep -i "${AD_GROUP_DN}" | cut -d : -f 2 | awk '{$1=$1};1')

# Map AD Group to Role
if [[ -z "$CHECK_AD_GROUP" ]]
then
  echo "Mapping AD Group to Scope..."
  uaac group map --name "${UAA_SCOPE}" "${AD_GROUP_DN}"
else
  printf "\nAD Group: '${AD_GROUP_DN}' already mapped to Scope: '${UAA_SCOPE}'\n"
  printf "\nSkipping Mapping\n"
fi
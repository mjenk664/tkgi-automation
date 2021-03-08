#!/bin/bash

set -e

# Login to UAA
uaa target "${UAA_TARGET}" --skip-ssl-validation

# Get Bearer Token
uaa get-client-credentials-token "${UAA_ADMIN_CLIENT_ID}" -s "${UAA_ADMIN_CLIENT_SECRET}"
FETCH_GROUPS=$(uaa list-group-mappings | jq '.[] | .externalGroup')

# get LDAP group mappings from YAML config
PKS_CLUSTERS_ADMIN=$(yq e -j "${LDAP_GROUPS_FILE}" | jq '.pks_clusters_admin' -r | jq -c '.[]')

## loop through group mappings
echo "Starting map of TKGI Scope: pks.clusters.admin"
for group in ${PKS_CLUSTERS_ADMIN[@]}
do
   if [[ $(echo "${FETCH_GROUPS}" | grep -e "${group}") == "" ]]
   then
        echo "No mapping found for LDAP Group: ${group}"
        echo "Mapping group: ${group} to 'pks.clusters.admin'"
        uaa map-group "${group}" pks.clusters.admin
   fi
done

PKS_CLUSTERS_MANAGE=$(yq e -j "${LDAP_GROUPS_FILE}" | jq '.pks_clusters_manage' -r | jq -c '.[]')
for group in ${PKS_CLUSTERS_MANAGE[@]}
do
   if [[ $(echo "${FETCH_GROUPS}" | grep -e "${group}") == "" ]]
   then
        echo "No mapping found for LDAP Group: ${group}"
        echo "Mapping group: ${group} to 'pks.clusters.manage'"
        uaa map-group "${group}" pks.clusters.manage
   fi
done
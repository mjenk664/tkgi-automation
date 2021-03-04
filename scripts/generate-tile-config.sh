#!/bin/bash -e
: ${PIVNET_TOKEN?"Need to set PIVNET_TOKEN"}
#set -x 


foundation=$1
product=$2

FOUNDATION=foundations/$foundation
OPS_DIR=foundations/$foundation/operations

if [ ! $# -eq 2 ]; then
  echo "Must supply environment name and product slug as appear in Ops Manger as args"
  printf "\n"
  echo "Example: $(basename $0) sbx-nane cf"
  printf "\n"
  exit 1
fi

echo "Generating configuration for product $product"
printf "\n"

versionfile="${FOUNDATION}/versions/$product.yml"
if [ ! -f ${versionfile} ]; then
  echo "Could not generate configs for $product. Must create ${versionfile} file first."
  printf "\n"
  exit 1
fi

version=$(bosh interpolate ${versionfile} --path /product-version)
glob=$(bosh interpolate ${versionfile} --path /pivnet-file-glob)
slug=$(bosh interpolate ${versionfile} --path /pivnet-product-slug)

tmpdir=tile-configs/${product}-config

mkdir -p ${tmpdir}

om config-template --output-directory=${tmpdir} --pivnet-api-token ${PIVNET_TOKEN} --pivnet-product-slug  ${slug} --product-version ${version} --pivnet-file-glob ${glob}

wrkdir=$(find ${tmpdir}/${product}* -name "${version}*")
if [ ! -f ${wrkdir}/product.yml ]; then
  echo "Something wrong with configuration as expecting ${wrkdir}/product.yml to exist"
  printf "\n"
  exit 1
fi

mkdir -p ${OPS_DIR}
ops_files="${OPS_DIR}/${product}-operations"
touch ${ops_files}

ops_files_args=("")
while IFS= read -r var
do
  # if there is a new line in the file, then ignore
  if [ -z $var ]; then
     #echo "Ignoring newline in file"
     continue
  elif [ ! -f "${wrkdir}/$var" ]; then
     printf "\n"
     printf "\nERROR: File does not exist for $var\n"
     printf "\n"
     exit 1
  else
     #printf "Found operations file for: $var\n"
     ops_files_args+=("-o ${wrkdir}/${var}")
  fi
done < "$ops_files"
bosh int ${wrkdir}/product.yml ${ops_files_args[@]} > ${FOUNDATION}/templates/${product}.yml

mkdir -p ${FOUNDATION}/defaults
rm -rf ${FOUNDATION}/defaults/${product}.yml
touch ${FOUNDATION}/defaults/${product}.yml

if [ -f ${wrkdir}/default-vars.yml ]; then
  cat ${wrkdir}/default-vars.yml >> ${FOUNDATION}/defaults/${product}.yml
fi

if [ -f ${wrkdir}/errand-vars.yml ]; then
  cat ${wrkdir}/errand-vars.yml >> ${FOUNDATION}/defaults/${product}.yml
fi

if [ -f ${wrkdir}/resource-vars.yml ]; then
  cat ${wrkdir}/resource-vars.yml >> ${FOUNDATION}/defaults/${product}.yml
fi


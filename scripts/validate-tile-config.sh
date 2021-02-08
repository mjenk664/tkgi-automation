#!/bin/bash -e

# Check that user has entered 2 arguments
if [ ! $# -eq 2 ]; then
  echo "Must supply environment name and product slug as appear in Ops Manger as args"
  printf "\n"
  echo "Example: $(basename $0) sbx-nane cf"
  printf "\n"
  exit 1
fi

# Read in arguments from user for product name and environment name
environment=$1
product=$2


printf "Validating configuration for product $product\n"

# source in the correct product version file for the given product
deploy_type=$(bosh int ${environment}/config/versions/${product}.yml --path /pivnet-file-glob)


vars_files_args=("")
# Check the defaults for the product for any missing properties
printf "Validating defaults for $product...\n"
if [ -f "${environment}/config/defaults/${product}.yml" ]; then
  vars_files_args+=("--vars-file ${environment}/config/defaults/${product}.yml")
fi

# Check the vars for the product for any missing properties
printf "Validating vars for $product...\n"
if [ -f "${environment}/config/vars/${product}.yml" ]; then
  vars_files_args+=("--vars-file ${environment}/config/vars/${product}.yml")
fi

# Check the secrets for the product for any missing properties
printf "Validating secrets for $product...\n"
if [ -f "${environment}/config/secrets/${product}.yml" ]; then
  vars_files_args+=("--vars-file ${environment}/config/secrets/${product}.yml")
fi

# Bosh Interpolate
# Compare and validate the defaults, vars, secrets against the Product's Template file
# This will check to make sure that we have filled in all the properties for the template
bosh int --var-errs ${environment}/config/templates/${product}.yml ${vars_files_args[@]}


# Use for later if we ever add stemcell files to config/versions
# Check stemcell files
#if [[ "${deploy_type}" == "*.tgz" ]]; then
#  vars_files_args+=("--vars-file ${environment}/config/versions/${product}.yml")
#fi

# Check the common-director for OpsManager + Bosh for any missing properties
#if [ -f "common/${product}.yml" ]; then
#  vars_files_args+=("--vars-file common/${product}.yml")
#fi

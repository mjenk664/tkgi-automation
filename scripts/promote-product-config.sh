#!/bin/bash -e

if [ ! $# -eq 3 ]; then
  echo "Must supply environment source, target, and product-slug"
  printf "\n"
  echo "Example: $(basename $0) hal pivotal-container-service"
  printf "\n"
  exit 1
fi

environment_source=$1
environment_target=$2
product_slug=$3
echo "Promoting from ${environment_source} to ${environment_target} for ${product_slug}"

mkdir -p foundations/${environment_target}/config/defaults
mkdir -p foundations/${environment_target}/config/vars
mkdir -p foundations/${environment_target}/config/secrets
mkdir -p foundations/${environment_target}/config/versions
mkdir -p foundations/${environment_target}/config/templates

cp -r foundations/${environment_source}/config/defaults/${product_slug}.yml foundations/${environment_target}/config/defaults/.
cp -r foundations/${environment_source}/config/versions/${product_slug}.yml foundations/${environment_target}/config/versions/.
cp -r foundations/${environment_source}/config/templates/${product_slug}.yml foundations/${environment_target}/config/templates/.
cp -r foundations/${environment_source}/config/secrets/${product_slug}.yml foundations/${environment_target}/config/secrets/.

#./validate-opsman-config.sh ${environment_target}

#products=("cf" "p-healthwatch")

#for product in ${products[@]}; do
#  ./validate-config.sh ${product} ${environment_target}
#done

# Generate Tile Configuration
Pivotal Platform Automation provides building blocks to create repeatable and reusable automated pipeline(s) for upgrading and installing Pivotal Platform foundations

The structure of this repository allows for multiple environments to be represented in a single repository

## foundations

The `foundations` folder holds the configuration for a given environment where there is a subfolder for the environment name. We are currently maintaining the following foundations:
- [ewd](foundations/ewd): EWD
- [hal](foundations/hal): HAL
- [del](foundations/del): DEL

### Configuration

Within each foundation's folder, there shall be the following subfolders:

* `defaults` - this folder contains the default values for a given tile.  This is generated by the `om config-template`  **Promotable**

* `templates` - this folder contains the resulting interpolated template based on operations files that have been applied to the output of `om config-template`.  This is created by `generate-tile-config.sh`  **Promotable**

* `vars` - this folder contains environment specific variables per product that is being deployed. **Not Promotable**

* `secrets` - this folder contains the templates that can be interpolated using `credhub interpolate` to be used as secrets inputs to other tasks **Promotable**

* `versions` - this folder contains both the product version and/or stemcell version per product. **Promotable**


## Configurations

#### Global configuration
- foundations/common/global-vars.yml

#### Operations Manager configuration template
- config/opsman.yml

#### Director configuration template
- config/director.yml

#### TKGI configuration template, defaults, vars, secrets
- foundations/{environment}/templates/pivotal-container-service.yml
- foundations/{environment}/defaults/pivotal-container-service.yml
- foundations/{environment}/vars/pivotal-container-service.yml
- foundations/{envionrment}/secrets/pivotal-container-service.yml

### How-To Generate a tile's configuration

#### Pre-requistes
You must ensure the following prerequisites are have been met to executing the `generate-tile-config.sh` script:
- Pivnet API Token
- OM CLI
- BOSH CLI

Perform the following steps to generate the tile configuration for a given product:
1. Create or Update the version file for that product in `foundations/{environment}/versions/${product}.yml` where product must match the tile product not the Pivnet slug (i.e., cf vs elastic-runtime).
2. Export the PIVNET_TOKEN environment variable with your pivnet API token from Pivotal Network
3. Run the following command with the environment name and tile product name

- `./generate-tile-config.sh <environment_name> <product_slug>`

Example:
- `./generate-tile-config.sh hal pivotal-container-service`

The script will generate the configs in the following directories:
- `foundations/{environment}/defaults/{product}.yml`
- `foundations/{environment}/templates/{product}.yml`

Do not modify the above two files directly. Instead, you will overwrite these values in the following product's `vars` and `secrets` files:
- `foundations/{environment}/vars/{product}.yml`
- `foundations/{environment}/secrets/{product}.yml`


The script will also generate a `product-operations` (i.e., cf-operations) file in the environment's `foundations/{environment}/operations` directory.

A `tiles-config` directory will be generated after running the script. You can find additional feature/operations files in this directory. Update this file to add the missing properties to your `{product}`.yml template file

*__You must re-run the script after updating it's operations file__

`./generate-tile config.sh <environment> <productt>`
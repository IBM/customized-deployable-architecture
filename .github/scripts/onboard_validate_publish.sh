#! /bin/bash

CATALOG_NAME=$1
OFFERING_NAME=$2
TARBALL_URL=$3
VERSION=$4
VARIATION=$5
RESOURCE_GROUP=$6
TIME_OUT=10800         # 3 hours - sufficiently large but will not be needed

echo "CatalogName:"$CATALOG_NAME
echo "OfferingName:"$OFFERING_NAME
echo "TarballURL:"$TARBALL_URL
echo "Version:"$VERSION
echo "Variation:"$VARIATION
echo "ResourceGroup:"$RESOURCE_GROUP

# import the version into the catalog
ibmcloud catalog offering import-version --zipurl "$TARBALL_URL" --target-version "$VERSION" --catalog "$CATALOG_NAME" --offering "$OFFERING_NAME" --include-config --flavor $VARIATION || ret=$?
if [[ ret -ne 0 ]]; then
    exit 1
fi    

# get the catalog's version locator for the version just uploaded
ibmcloud catalog offering get --catalog "$CATALOG_NAME" --offering "$OFFERING_NAME" --output json > offering.json
versionLocator=$(jq -r --arg version $VERSION '.kinds[] | select(.format_kind=="terraform").versions[] | select(.version==$version).version_locator' < offering.json)
echo "version locator: $versionLocator"

# need to target a resource group - deployed resources will be in this resource group
ibmcloud target -g "$RESOURCE_GROUP"

# invoke schematics service to validate the version
ibmcloud catalog offering version validate --vl "$versionLocator" --override-values validation-values.json --timeout $TIME_OUT || ret=$?

if [[ ret -eq 0 ]]; then
    # run CRA scan
    ibmcloud catalog offering version cra --vl ${versionLocator}

    # mark the version as ready in the catalog
    ibmcloud catalog offering ready --vl "$versionLocator" 
fi
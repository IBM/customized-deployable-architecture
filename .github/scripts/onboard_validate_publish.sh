#! /bin/bash

#
# this function generates values that will be used as deploy values during the validation of the offering version.
function generateValidationValues() {
    local validationValues=$1

    # generate an ssh key that can be used as a validation value. overwrite file if already there. 
    FILE=./id_rsa.pub
    if [ ! -f "$FILE" ]; then
        ssh-keygen -f ./id_rsa -t rsa -N '' <<<y
    fi

    SSH_KEY=$(cat ./id_rsa.pub)
    SSH_PRIVATE_KEY="$(cat ./id_rsa)"

    # format offering validation values into json format
    jq -n --arg IBMCLOUD_API_KEY "$IBMCLOUD_API_KEY" --arg SSH_KEY "$SSH_KEY" --arg SSH_PRIVATE_KEY "$SSH_PRIVATE_KEY" '{ "ibmcloud_api_key": $IBMCLOUD_API_KEY, "prefix": "validation", "ssh_key": $SSH_KEY, "ssh_private_key": $SSH_PRIVATE_KEY }' > "$validationValues"

    echo "Validation values are:"
    cat "$validationValues"
}

#
# this function imports an offering version into a catalog.
function importVersionToCatalog() {
    local tarballURL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/archive/refs/tags/${VERSION}.tar.gz"

    # import the version into the catalog
    ibmcloud catalog offering import-version --zipurl "$tarballURL" --target-version "$VERSION" --catalog "$CATALOG_NAME" --offering "$OFFERING_NAME" --include-config --flavor $VARIATION || ret=$?
    if [[ ret -ne 0 ]]; then
        exit 1
    fi    
}

# 
# this function querys the catalog and retrieves the version locator for a version.
function getVersionLocator() {
    # get the catalog version locator for an offering version
    ibmcloud catalog offering get --catalog "$CATALOG_NAME" --offering "$OFFERING_NAME" --output json > offering.json
    VERSION_LOCATOR=$(jq -r --arg version $VERSION '.kinds[] | select(.format_kind=="terraform").versions[] | select(.version==$version).version_locator' < offering.json)
    echo "version locator is:"${VERSION_LOCATOR}
}

#
# this function calls the schematics service and validates the version.
function validateVersion() {
    local validationValues="validation-values.json"
    local timeOut=10800         # 3 hours - sufficiently large.  will not run this long.    

    generateValidationValues "${validationValues}"
    getVersionLocator 

    # need to target a resource group - deployed resources will be in this resource group
    ibmcloud target -g "${RESOURCE_GROUP}"

    # invoke schematics service to validate the version
    ibmcloud catalog offering version validate --vl ${VERSION_LOCATOR} --override-values "${validationValues}" --timeout $timeOut || ret=$?

    if [[ ret -ne 0 ]]; then
        exit 1
    fi
}

#
# this function invokes a CRA scan on a validated version.
function scanVersion() {
    ibmcloud catalog offering version cra --vl ${VERSION_LOCATOR}
}

#
# this function marks a validated version as 'Ready'
function publishVersion() {
    ibmcloud catalog offering ready --vl ${VERSION_LOCATOR}
}


# ------------------------------------------------------------------------------------
#  main
# ------------------------------------------------------------------------------------

CATALOG_NAME=$1
OFFERING_NAME=$2
VERSION=$3
VARIATION=$4
RESOURCE_GROUP=$5

echo "CatalogName:"$CATALOG_NAME
echo "OfferingName:"$OFFERING_NAME
echo "Version:"$VERSION
echo "Variation:"$VARIATION
echo "ResourceGroup:"$RESOURCE_GROUP

# steps
importVersionToCatalog 
validateVersion 
scanVersion
publishVersion
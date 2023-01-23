

#
# this function generates values that will be used as deployment values during the validation of the offering version.
function generateValidationValues() {
    local validationValues=$1

    # we only need to do this once.
    FILE=$1
    if [ -f "$FILE" ]; then
        return
    fi

    # generate an ssh key that can be used as a validation value. overwrite file if already there. 
    ssh-keygen -f ./id_rsa -t rsa -N '' <<<y

    SSH_KEY=$(cat ./id_rsa.pub)
    SSH_PRIVATE_KEY="$(cat ./id_rsa)"

    # use a unique prefix string value 
    SUFFIX="$(date +%m%d-%H-%M)"
    PREFIX="val-${SUFFIX}"

    # format offering validation values into json format.  the json keys used here match the names of the defined deployment variables.  
    jq -n --arg IBMCLOUD_API_KEY "$IBMCLOUD_API_KEY" --arg PREFIX "$PREFIX" --arg SSH_KEY "$SSH_KEY" --arg SSH_PRIVATE_KEY "$SSH_PRIVATE_KEY" '{ "ibmcloud_api_key": $IBMCLOUD_API_KEY, "prefix": $PREFIX, "ssh_key": $SSH_KEY, "ssh_private_key": $SSH_PRIVATE_KEY }' > "$validationValues"
}

#
# this function imports a version of an existing offering into a catalog.
function importVersionToCatalog() {
    local tarballURL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/archive/refs/tags/${VERSION}.tar.gz"

    # import the version into the catalog.  the offering already exists.
    ibmcloud catalog offering import-version --zipurl "$tarballURL" --target-version "$VERSION" --catalog "$CATALOG_NAME" --offering "$OFFERING_NAME" --include-config --variation $VARIATION --format-kind $FORMAT_KIND || ret=$?
    if [[ ret -ne 0 ]]; then
        exit 1
    fi    
}

# 
# this function querys the catalog and retrieves the version locator for a version.
function getVersionLocator() {
    # get the catalog version locator for an offering version
    ibmcloud catalog offering get --catalog "$CATALOG_NAME" --offering "$OFFERING_NAME" --output json > offering.json
    VERSION_LOCATOR=$(jq -r --arg version $VERSION --arg format_kind $FORMAT_KIND '.kinds[] | select(.format_kind==$format_kind).versions[] | select(.version==$version).version_locator' < offering.json)
    echo "version locator is:"${VERSION_LOCATOR}
}

#
# this function calls the schematics service and validates a verion of the offering.
function validateVersion() {
    local validationValues="validation-values.json"
    local timeOut=10800         # 3 hours - sufficiently large.  will not run this long.    

    # generate values for the deployment variables defined for this version of the offering
    generateValidationValues "${validationValues}"
    getVersionLocator 

    # need to target a resource group - deployed resources will be in this resource group
    ibmcloud target -g "${RESOURCE_GROUP}" -r "us-south"

    # invoke schematics service to validate the version.  this will wait for that operation to complete.
    ibmcloud catalog offering version validate --vl ${VERSION_LOCATOR} --override-values "${validationValues}" --timeout $timeOut || ret=$?

    if [[ ret -ne 0 ]]; then
        exit 1
    fi
}

#
# this function invokes a CRA scan on a validated version.
function scanVersion() {
    if [ "$CRA_SCAN" = SCAN ]; then
        ibmcloud catalog offering version cra --vl ${VERSION_LOCATOR}
    else
        echo "CRA scan skipped"
    fi    
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
FORMAT_KIND=$6
CRA_SCAN=$7

echo "CatalogName:"$CATALOG_NAME
echo "OfferingName:"$OFFERING_NAME
echo "Version:"$VERSION
echo "Variation:"$VARIATION
echo "ResourceGroup:"$RESOURCE_GROUP
echo "FormatKind:"$FORMAT_KIND

# steps
importVersionToCatalog 
validateVersion 
scanVersion
publishVersion
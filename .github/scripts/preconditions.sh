#! /bin/bash

# Preconditions for a good run of the EPX onboarding are:
#  - an SCC instance must exist
#  - catalog must exist
#  - offering must exist
#  - project must exist
#
#  if trusted profile authorization is being used, then are the CRNs contained within it.
#  if api key authorization is being used, then does the api key exist?
#
#  is the catalog account context there with the project and either the api key or trusted profile specified.
#
#  service to service authorization checking
#


function validateProject() {
    local projectName=$1

    # project needs to exist
    projectId=$(ibmcloud project list --output json | jq -r --arg projectname "$projectName" '.projects[] | select(.definition.name==$projectname).id') 

    echo "Step 2. checking existance of Project"

    if [[ "$projectId" != null ]]; then
        # there is no existing project
        echo "-- success: Project \"$projectName\" exists and its id is $projectId"
    else
        echo "-- failed.  The project \"$projectName\" does not yet exist."
        exit 1    
    fi
}

function validateCatalog() {
    local catalogName=$1
    local offeringName=$2
    local projectName=$3
    local authorization=$4

    # catalog needs to exist
    catalogId=$(ibmcloud catalog list --output json | jq -r --arg catalogname "$catalogName" '.[] | select(.label==$catalogname).id')

    echo "Step 3. checking existance of Catalog"
    if [[ "$catalogId" != null ]]; then
        # there is no existing project
        echo "-- success: Catalog \"$catalogName\" exists and its id is $catalogId"
    else
        echo "-- failed.  The catalog \"$catalogName\" does not yet exist."
        exit 1    
    fi

    # see if the catalog offering exists yet
    offeringId=$(ibmcloud catalog offerings -c "$catalogName" --output json | jq -r --arg offeringname "$offeringName" '.resources[] | select(.label==$offeringname).id')

    echo "Step 4.  checking existance of offering"
    if [[ "$offeringId" != null ]]; then
        echo "-- success: offering \"$offeringName\" exists in catalog \"$catalogName\" and its id is $offeringId."
    else
        echo "-- failed.  offering \"$offeringName\" does not yet exist."
    fi

    # query the catalog to see if the account context has been setup
    validateCatalogAccountContext "$catalogName" "$projectName" "$authorization"
}

function validateCatalogAccountContext() {
    local catalogName=$1
    local projectName=$2
    local authorization=$3

    echo "Step 5. checking for Project to Catalog link via target account configuration"
    # see if the account context exists between the catalog and the project with the correct authorization method
    targetAccounts=$(ibmcloud catalog target-account list -c "$catalogName" -output json)
    if [[ "$targetAccounts" == "No target accounts found in this catalog" ]]; then
        echo "-- failed. The catalog does not have any target account contexts configured with a project."
        exit 1
    fi    

    targetAccounts=$(ibmcloud catalog target-account list -c "$catalogName" -output json | jq -r '. | length')

    if [[ $targetAccounts -gt 0 ]]; then
        projectId=$(ibmcloud project list --output json | jq -r --arg projectname "$projectName" '.projects[] | select(.definition.name==$projectname).id')

        targetAccount=$(ibmcloud catalog target-account list -c "$catalogName" -output json | jq -r --arg projectid "$projectId" '.[] | select(.project_id==$projectid)')

        # if not an empty string
        if [[ -n $targetAccount ]]; then
            # look for the authorization of either api key or trusted profile
            echo "-- success: found the project in a catalog target account context."

            if [[ $authorization == "apikeyauth" ]]; then
                api=$(echo "$targetAccount" | jq -r '.api_key')
                if [[ "$api" != null ]]; then
                    echo "-- success: found an api key configured with the project."
                else
                    echo "-- failed. Api key missing in the target account context configuration in the catalog."
                fi    
            elif [[ $authorization == "trustedprofileauth" ]]; then
                tp=$(echo "$targetAccount" | jq -r '.trusted_profile')
                if [[ "$tp" != null ]]; then
                    tpId=$(echo "$targetAccount" | jq -r '.trusted_profile.trusted_profile_id')
                    echo "-- success: found a trusted profile configured with the project and its id is $tpId."
                else
                    echo "-- failed. A trusted profile id is missing in the target account context configuration in the catalog."  
                fi    
            fi
        else
            echo "-- failed. The project has not been configured with the catalog as a target account context."
        fi
    else
        echo "-- failed. The catalog does not have any target account contexts configured with a project."
        exit 1
    fi    

}

function validateSCC() {
    local instanceId=$1
    local sccRegion=$2

    # verify that this instance exists
    SCC_API_BASE_URL="https://$sccRegion.compliance.test.cloud.ibm.com/instances/$instanceId/v3"

    # use api key to get an access token
    IAM_RESPONSE=$(curl -s --request POST \
        'https://iam.test.cloud.ibm.com/identity/token' \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --header 'Accept: application/json' \
        --data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' --data-urlencode 'apikey='"${SCC_API_KEY}") 

    ERROR_MESSAGE=$(echo "${IAM_RESPONSE}" | jq 'has("errorMessage")')
    if [[ "${ERROR_MESSAGE}" != false ]]; then
        echo "${IAM_RESPONSE}" | jq '.errorMessage'
        echo "Could not obtain an access token"
        exit 1
    fi

    ACCESS_TOKEN=$(echo "${IAM_RESPONSE}" | jq -r '.access_token')

    PROFILE_JSON=$(curl --silent --location --request GET \
        "${SCC_API_BASE_URL}/profiles" \
        --header 'Content-Type: application/json' \
        --header 'Authorization: Bearer '"${ACCESS_TOKEN}")

    echo "Step 1. checking for SCC instance."

    numberProfiles=$(echo "${PROFILE_JSON}" | jq -r '.total_count')
    if [[ $numberProfiles > 0 ]]; then
        echo "-- success: SCC instance exists for this account so scans may be ran."
    else
        echo "-- failed. An SCC instance was not detected.  Scans not yet possible."    
    fi
}

#######
# main 
#######

catalogName=$1
offeringName=$2
projectName=$3
sccInstanceId=$4
sccRegion=$5
authorization=$6  # api key or trusted profile

echo "Checking for necessary pre-condition setup between catalog $catalogName and project $projectName"
echo

validateSCC "$sccInstanceId" "$sccRegion"
validateProject "$projectName" 
validateCatalog "$catalogName" "$offeringName" "$projectName" "$authorization"

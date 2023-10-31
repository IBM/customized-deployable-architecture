#! /bin/bash

function validateLoggedIn() {

    numRegions=$(ibmcloud regions --output json | jq '. | length' )
    if [[ $numRegions -eq 0 ]]; then
        echo "To begin login under the account that owns the catalog."
        exit 1
    fi  
}

function validateProject() {
    local projectName=$1
    projectCrn=$2
    step=$3

    # are there any projects at all?
    anyProjects=$(ibmcloud project list --output json | jq 'has("projects")')
    if [[ $anyProjects == true ]]; then
        # project needs to exist
        projectId=$(ibmcloud project list --output json | jq -r --arg projectname "$projectName" '.projects[] | select(.definition.name==$projectname).id') 

        step=$((step+1))
        echo "Step $step . checking existence of Project"

        if [[ "$projectId" != "" ]]; then
            # there is no existing project
            echo "-- success: Project \"$projectName\" exists and its id is $projectId"
            projectCrn=$(ibmcloud project list --output json | jq -r --arg projectname "$projectName" '.projects[] | select(.definition.name==$projectname).crn')
        else
            echo "-- failed.  The project \"$projectName\" does not yet exist."
            exit 1    
        fi
    else
        echo "-- failed.  The project \"$projectName\" does not yet exist.  There are no projects defined yet."
    fi
    
}

function validateCatalog() {
    local catalogName=$1
    local offeringName=$2
    local projectName=$3
    local authorization=$4
    trustedProfileId=$5
    catalogCrn=$6
    step=$7

    numberCatalogs=$(ibmcloud catalog list --output json | jq '. | length')
    if [[ $numberCatalogs -eq 0 ]]; then
        echo "-- failed.  No catalogs were found under this account."
        exit 1
    fi

    # catalog needs to exist
    catalogId=$(ibmcloud catalog list --output json | jq -r --arg catalogname "$catalogName" '.[] | select(.label==$catalogname).id')

    step=$((step+1))
    echo "Step $step. checking existence of Catalog"
    if [[ "$catalogId" != "" ]]; then
        # there is no existing project
        echo "-- success: Catalog \"$catalogName\" exists and its id is $catalogId"
        catalogCrn=$(ibmcloud catalog list --output json | jq -r --arg catalogname "$catalogName" '.[] | select(.label==$catalogname).crn')
    else
        echo "-- failed.  The catalog \"$catalogName\" does not yet exist."
        exit 1    
    fi

    # see if the catalog offering exists yet
    offeringId=$(ibmcloud catalog offerings -c "$catalogName" --output json | jq -r --arg offeringname "$offeringName" '.resources[] | select(.label==$offeringname).id')

    step=$((step+1))
    echo "Step $step.  checking existence of offering"
    if [[ "$offeringId" != null ]]; then
        echo "-- success: offering \"$offeringName\" exists in catalog \"$catalogName\" and its id is $offeringId."
    else
        echo "-- failed.  offering \"$offeringName\" does not yet exist."
    fi

    # query the catalog to see if the account context has been setup
    validateCatalogAccountContext "$catalogName" "$projectName" "$authorization" "$trustedProfileId" "$step"
}

function validateCatalogAccountContext() {
    local catalogName=$1
    local projectName=$2
    local authorization=$3
    trustedProfileId=$4
    step=$5

    step=$((step+1))
    echo "Step $step. checking for Project to Catalog link via target account configuration"
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

            if [[ $authorization == "apikey" ]]; then
                api=$(echo "$targetAccount" | jq -r '.api_key')
                if [[ "$api" != null ]]; then
                    echo "-- success: found an api key configured with the project."
                else
                    echo "-- failed. Api key missing in the target account context configuration in the catalog."
                fi    
            elif [[ $authorization == "trustedprofile" ]]; then
                tp=$(echo "$targetAccount" | jq -r '.trusted_profile')
                if [[ "$tp" != null ]]; then
                    trustedProfileId=$(echo "$targetAccount" | jq -r '.trusted_profile.trusted_profile_id')
                    echo "-- success: found a trusted profile configured with the project and its id is $trustedProfileId."
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
    step=$3

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

    step=$((step+1))
    echo "Step $step. checking for SCC instance - switching to SCC account."

    numberProfiles=$(echo "${PROFILE_JSON}" | jq -r '.total_count')
    if [[ $numberProfiles -gt 0 ]]; then
        echo "-- success: SCC instance exists for this account so scans may be ran."
    else
        echo "-- failed. An SCC instance was not detected.  Scans not yet possible."    
    fi
}

function validateService2Service() {
    local catalogCrn=$1
    local projectCrn=$2
    local authorizationMethod=$3
    local trustedProfileId=$4
    step=$5

    step=$((step+1))
    echo "Step $step. checking for service to service authorizations - switching to target account."

    # need to be sure to be logged in under the target account to be able to list the IAM authorizations
    ibmcloud login --apikey "${TARGET_ACCOUNT_API}" -a https://test.cloud.ibm.com -r us-south --quiet 2>/dev/null 1>/dev/nul
    
    # validate the service to service authorizations 
    authorizations=$(ibmcloud iam authorization-policies --output json | jq -r '. | length')
    if [[ $authorizations -gt 0 ]]; then
        # find a service to service authorization between Projects and Catalog
        project2catalog=$(ibmcloud iam authorization-policies --output json | jq -r '.[] | select(.subjects[].attributes[].value=="project") | select(.resources[].attributes[].value=="globalcatalog-collection").roles[].display_name')
        if [[ $project2catalog != "" ]]; then
            echo "-- success: A service to service authorization was detected between Projects and Global Catalog."
        else
            echo "-- failed.  A service to service authorization was not detected between Projects and Global Catalog."
        fi
    else
        echo "-- failed. No service to service authorizations found under target account."
    fi

    # validate the crns of the catalog and the project are contained within the trusted profile if using
    # trusted profile authorization.
    if [[ $authorizationMethod == "trustedprofile" ]]; then
        # does the trusted profile exist?
        tpFound=$(ibmcloud iam tp "$trustedProfileId" --output json)
        if [[ $tpFound != *"not found"* ]]; then
            # see if any crns are defined within the trusted profile
            identities=$(ibmcloud iam trusted-profile-identities "$trustedProfileId" --output json --quiet | jq -r '. | length')
            if [[ $identities -gt 0 ]]; then
                # look for the CRNs of the project and the catalog
                catalogFound=$(ibmcloud iam trusted-profile-identities "$trustedProfileId" --output json | jq -r --arg crn "$catalogCrn" '.[] | select(.identifier==$crn)')
                projectFound=$(ibmcloud iam trusted-profile-identities "$trustedProfileId" --output json | jq -r --arg crn "$projectCrn" '.[] | select(.identifier==$crn)')

                if [[ "$catalogFound" != "" && "$projectFound" != "" ]]; then
                    echo "-- success: Both the catalog and project CRNs are configured in the trusted profile."
                else
                    echo "-- failed. Both the catalog and project CRNs must be defined in the trusted profile.  One or more is missing."
                fi
            else
                echo "-- failed.  The trusted profile, $trustedProfileId, does not have any CRNs configured."
            fi
        else
            echo "-- failed.  The trusted profile, $trustedProfileId, configured with the catalog was not found."
            exit 1
        fi

        # find a service to service authorization between Schematics and Catalog
        if [[ $authorizations -gt 0 ]]; then
            schematics2catalog=$(ibmcloud iam authorization-policies --output json | jq -r '.[] | select(.subjects[].attributes[].value=="schematics") | select(.resources[].attributes[].value=="globalcatalog-collection").roles[].display_name')
            if [[ $schematics2catalog != "" ]]; then
                echo "-- success: A service to service authorization was detected between Schematics and Global Catalog."
            else
                echo "-- failed.  A service to service authorization was not detected between Schematics and Global Catalog."
            fi
        fi
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
trustedProfileId=""
projectCrn=""
catalogCrn=""

echo "This script will validate that the necessary configuration has been setup to use a Project to "
echo "track the onboarding and validation of a new version of an offering.  A Project supports "
echo "two kinds of authorization mechanisms, an api key or trusted profile, so one or the other will be "
echo "needed here.  If a trusted profile is used, then the CRNs of the catalog and the project need to "
echo "be defined in the \"Trust relationship\" - IBM Cloud services section of the trusted profile."
echo
echo "You should be logged in to the IBM Cloud with the account that owns the Catalog and Project before "
echo "proceeding.  If you are not, then exit, login and restart this script."
echo "Continue? [y|N]"
read -r reply
if [[ $reply != y* ]]; then
    echo "Stopping."
    exit 1
fi
echo 

step=0

validateLoggedIn
# login for this steps with api key for account that owns catalog and project
validateProject "$projectName" "$projectCrn" "$step"
validateCatalog "$catalogName" "$offeringName" "$projectName" "$authorization" "$trustedProfileId" "$catalogCrn" "$step"

# login for this step with an api key for target account which owns the trusted profile 
validateService2Service "$catalogCrn" "$projectCrn" "$authorization" "$trustedProfileId" "$step"

# login for this step with an api key for an account that has an SCC instance
validateSCC "$sccInstanceId" "$sccRegion" "$step"
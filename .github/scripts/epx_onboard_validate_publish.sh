#! /bin/bash

#
# the setup or pre-requisites for this script are that a catalog and project already exist.  They are also alreay linked by adding an account 
# context to the catalog identifying the project and an api key as the authorization mechanism.
#

function onboardVersionToCatalog() {
    local tarBall=$1
    local version=$2
    local catalogName=$3
    local offeringName=$4
    local variationLabel=$5
    local formatKind=$6
    local installType=$7
    versionLocator=$8

    # if executing from a github action then the url does not need to be given to this script.  it can be determined.
    if [[ "$tarBall" == "" ]]; then
        tarBall="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/archive/refs/tags/${version}.tar.gz"
    fi
    # determine the offering's product kind in the catalog.
    productKind=""
    getProductKind "$catalogName" "$offeringName" "$productKind"   

    # onboard to an existing catalog with an existing offering - just import a version.  module offerings do not have an installType
    if [[ "$productKind" == "module" ]]; then
        ibmcloud catalog offering import-version --zipurl "$tarBall" --target-version "$version" --catalog "$catalogName" --offering "$offeringName" --variation-label "$variationLabel" --format-kind "$formatKind" --include-config
    else
        ibmcloud catalog offering import-version --zipurl "$tarBall" --target-version "$version" --catalog "$catalogName" --offering "$offeringName" --variation-label "$variationLabel" --format-kind "$formatKind" --install-type "$installType" --include-config
    fi

    if [[ $? -eq 1 ]]; then
        echo "error importing version to catalog."
        exit 1
    fi

    # determine the catalog's version locator string for this version
    getVersionLocator "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType" "$formatKind" "$versionLocator"
    echo "the version locator is $versionLocator"
}


function getProductKind() {
    local catalogName=$1
    local offeringName=$2
    productKind=$3

    # get the product kind
    ibmcloud catalog offering get --catalog "$catalogName" --offering "$offeringName" --output json > offering.json
    productKind=$(jq -r '.product_kind' < offering.json)

}

# 
# this function querys the catalog and retrieves the version locator for a version.
function getVersionLocator() {
    local catalogName=$1
    local offeringName=$2
    local version=$3
    local variationLabel=$4
    local installType=$5
    local formatKind=$6
    versionLocator=$7

    # get the catalog version locator for an offering version
    ibmcloud catalog offering get --catalog "$catalogName" --offering "$offeringName" --output json > offering.json
    if [[ $installType != "module" ]]; then
        versionLocator=$(jq -r --arg version "${version}" --arg variationLabel "${variationLabel}" --arg installType "${installType}" --arg format_kind "$formatKind" '.kinds[] | select(.format_kind==$format_kind).versions[] | select(.version==$version) | select(.solution_info.install_type == $installType) | select(.flavor.label==$variationLabel).version_locator' < offering.json)
    else
        versionLocator=$(jq -r --arg version "${version}" --arg variationLabel "${variationLabel}" --arg format_kind "$formatKind" '.kinds[] | select(.format_kind==$format_kind).versions[] | select(.version==$version) | select(.flavor.label==$variationLabel).version_locator' < offering.json)
    fi
}

function getProjectConfigurationId() {
    local projectId=$1
    local offeringName=$2
    local version=$3
    local versionLocator=$4
    configId=$5

    # make sure that the projects service has created a project configuration for this version.  check for no configurations.
    attempts=0
    configs=$(ibmcloud project --project-id "$projectId" configs --output json | jq -e '. == {}')
    while [[ $attempts -le 3 ]] && [[ "$configs" == "true" ]]
    do
        sleep 10
        configs=$(ibmcloud project --project-id "$projectId" configs --output json | jq -e '. == {}')
        attempts=$((attempts+1))
    done

    if [[ "$configs" == "true" ]]; then
        echo "no project configurations found after 30 seconds. exiting."
        exit 1
    fi

    configId=$(ibmcloud project --project-id "$projectId" configs --output json | jq -r --arg versionLocator "$versionLocator" '.configs[] | select(.definition.locator_id==$versionLocator).id')

    if [[ $configId == "" ]]; then
        echo "a project configuration for $offeringName, $version, $versionLocator was not found as expected.  exiting"
        exit 1
    fi
}

function getProjectIdFromName() {
    local projectName=$1
    projectId=$2

    projectId=$(ibmcloud project list --output json | jq -r --arg projectname "$projectName" '.projects[] | select(.definition.name==$projectname).id')
    echo "Project id is: $projectId for project named $projectName"
}

function generateValidationValues() {
    inputString=$1

    # generate an ssh key that can be used as a validation value. overwrite file if already there.
    # we only need to do this once.
    FILE="./id_rsa"
    if [ ! -f "$FILE" ]; then
        # generate an ssh key that can be used as a validation value.
        ssh-keygen -f ./id_rsa -t rsa -N '' <<<y
    fi

    SSH_KEY=$(cat ./id_rsa.pub)

    # use a unique prefix string value 
    SUFFIX="$(date +%m%d-%H-%M)"
    PREFIX="epx-${SUFFIX}"

    # construct a json string and substitute values for the deployment parameters for this offering version.  
    inputString="--input="$(jq -n --arg prefix "$PREFIX" --arg sshkey "$SSH_KEY" '[{"name": "prefix", "value":$prefix}, {"name": "ssh_key", "value": $sshkey}]')

    echo "validation values are: $inputString"
}    

function validateProjectConfig() {
    local projectId=$1
    local offeringName=$2
    local version=$3
    local versionLocator=$4
    configId=$5

    getProjectConfigurationId "$projectId" "$offeringName" "$version" "$versionLocator" "$configId"
    echo "project configuration id is: $configId"
   
    # update the project's config with values to use for validate/deploy.  Authorization method and value on the config is already set by catalog from the trusted profile setting on the catalog/project link up.
    echo "updating project configuration with values for validation"

    # generate/retrieve validation deployment values for this offering version
    inputString=""
    generateValidationValues "$inputString" 

    # these values are specific to the offering version 
    ibmcloud project config-update --project-id "$projectId"  --id "$configId" "$inputString"

    if [[ $? -eq 1 ]]; then
        echo "error attempting to update the project configuration with configuration values for validation."
        exit 1
    fi
    echo "project configuration updated"

    # validate via projects.  this only starts the job.  need to poll to get status
    ibmcloud project --project-id "$projectId" --id "$configId" config-check
    if [[ $? -eq 1 ]]; then
        echo "error attempting to validate the project configuration."
        exit 1
    fi
    echo "started project configuration validate/check"

    # wait and poll until state is "pipeline_failed" for now.  fails due to SCC.  look for state when SCC passes also
    attempts=0
    state=$(ibmcloud project --project-id "$projectId" --id "$configId" config-get --output json | jq -r '.pipeline_state')
    echo "project config validation status: $state"
    while [[ $attempts -le 240 ]] && [[ "$state" != "pipeline_failed" ]] && [[ "$state" != "pipeline_passed" ]]
    do
        sleep 15
        state=$(ibmcloud project --project-id "$projectId" --id "$configId" config-get --output json | jq -r '.pipeline_state')
        echo "project config validation status: $state"
        attempts=$((attempts+1))
    done

    # the config-check has finished and is showing a state of "pipeline_failed".  Make sure that the reason for the state
    # is due to only the fail of the SCC/CRA step.
    validateSuccess="false"
    ibmcloud project --project-id "$projectId" --id "$configId" config-get --output json > version.json
    if [[ $(jq -r '.job_summary.plan_summary.failed' < version.json) == 0 ]]; then
        if [[ $(jq -r '.job_summary.plan_messages.error_messages | length' < version.json) == 0 ]]; then
            if [[ $(jq -r '.cra_logs.status' < version.json) == "failed" ]]; then
                validateSuccess="true"
            fi
        fi
    fi

    if [[ $validateSuccess == "false" ]]; then
        echo "the project configuration did not pass validation."
        exit 1
    fi
}

function installProjectConfig() {
    local projectId=$1
    configId=$2

    # eventually do a force approve to get past failed SCC
    ibmcloud project --project-id "$projectId" --id "$configId" --comment "cli pipeline" force-approve
    if [[ $? -eq 1 ]]; then
        echo "error attempting to force approve the project configuration."
        exit 1
    fi

    # run a projects deploy
    ibmcloud project --project-id "$projectId" --id "$configId" config-install 
    if [[ $? -eq 1 ]]; then
        echo "error attempting to install the project configuration."
        exit 1
    fi
    echo "project configuration deploy started"

    # wait and poll until state is "installed"
    attempts=0
    state=$(ibmcloud project --project-id "$projectId" --id "$configId" config-get --output json | jq -r '.state')
    echo "project config deploy status: $state"
    while [[ $attempts -le 240 ]] && [[ "$state" != "installed" ]]
    do
        sleep 15
        state=$(ibmcloud project --project-id "$projectId" --id "$configId" config-get --output json | jq -r '.state')
        echo "project config deploy status: $state"
        attempts=$((attempts+1))
    done
}

function validateInstallProjectConfig() {
    local projectId=$1
    local offeringName=$2
    local version=$3
    local versionLocator=$4
    configId=$5

    # do a Project config-check and wait for it to finish
    validateProjectConfig "$projectId" "$offeringName" "$version" "$versionLocator" "$configId"
    # do a Project config-install and wait for it to finish
    installProjectConfig "$projectId" "$configId" 
} 

function publishVersion() {
    local versionLocator=$1

    # publish the new version
    ibmcloud catalog offering ready --version-locator "$versionLocator"
}

function runComplianceScan() {
    local offeringName=$1
    local variationLabel=$2
    local versionLocator=$3
    local sccInstanceId=$4
    local sccRegion=$5

    # from the ibm_catalog.json file determine the SCC profile name and version
    scc_profile_name=$(jq -r '.products[] | select(.name=="custom-deployable-arch").flavors[] | select(.label=="BabySLZ").compliance.controls[0].profile.name' < ibm_catalog.json)
    scc_profile_version=$(jq -r '.products[] | select(.name=="custom-deployable-arch").flavors[] | select(.label=="BabySLZ").compliance.controls[0].profile.version' < ibm_catalog.json)

    if [[ -n $scc_profile_name && -n $scc_profile_version ]]; then
        # run a scan and apply results to version
        echo "Running SCC scan for profile $scc_profile_name version $scc_profile_version"
        ./.github/scripts/perform-sccv3-scan.sh --profile_name="$scc_profile_name" --profile_version="$scc_profile_version" --account_id="$SCC_ACCOUNT_ID" --instance_id="$sccInstanceId" --scc_region="$sccRegion" --version_locator="$versionLocator"
    fi
}

function cleanUpResources() {
    local projectId=$1
    local configId=$2
    local vl=$3

    # cleanup 
    ibmcloud project --project-id "$projectId" --id "$configId" config-uninstall
    if [[ $? -eq 1 ]]; then
        echo "error attempting to uninstall the project configuration."
        exit 1
    fi

    attempts=0
    state=$(ibmcloud project --project-id "$projectId" --id "$configId" config-get --output json | jq -r '.state')
    echo "project config resource clean up status: $state"
    while [[ $attempts -le 240 ]] && [[ "$state" != "not_installed" ]]
    do
        sleep 15
        state=$(ibmcloud project --project-id "$projectId" --id "$configId" config-get --output json | jq -r '.state')
        echo "project config resource clean up status: $state"
        attempts=$((attempts+1))
    done

    # delete the validation workspace and resources? - insert code to get workspace id used for the projects deploy
    workspaceId=$(ibmcloud catalog offering version workspaces -version-locator "$vl" --output json | jq -r '.resources[].id')
    echo "config validation/deploy workspace is: " "$workspaceId"

    #ibmcloud schematics ws delete -id $workspaceId
}


# ------------------------------------------------------------------------------------
#  main
# ------------------------------------------------------------------------------------

projectName=$1
catalogName=$2
offeringName=$3
version=$4
variationLabel=$5
formatKind=$6
installType=$7
sccInstanceId=$8
sccRegion=$9
tarBall=${10}

# these values will be determined and set
configId=""
versionLocator=""
projectId=""

getProjectIdFromName "$projectName" "$projectId"

# main steps 
onboardVersionToCatalog "$tarBall" "$version" "$catalogName" "$offeringName" "$variationLabel" "$formatKind" "$installType" "$versionLocator"
validateInstallProjectConfig "$projectId" "$offeringName" "$version" "$versionLocator" "$configId"
runComplianceScan "$offeringName" "$variationLabel" "$versionLocator" "$sccInstanceId" "$sccRegion"
publishVersion "$versionLocator"
cleanUpResources "$projectId" "$configId" "$versionLocator"

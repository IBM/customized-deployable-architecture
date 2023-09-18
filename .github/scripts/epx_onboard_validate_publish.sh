#! /bin/bash

function onboardVersionToCatalog() {
    local tarBall=$1
    local version=$2
    local catalogName=$3
    local offeringName=$4
    local variationLabel=$5
    local formatKind=$6
    local installType=$7

    # onboard to catalog
    ibmcloud catalog offering import-version --zipurl "$tarBall" --target-version "$version" --catalog "$catalogName" --offering "$offeringName" --variation-label "$variationLabel" --format-kind "$formatKind" --install-type "$installType" 
    if [[ $? -eq 1 ]]; then
        echo "error importing version to catalog."
        exit 1
    fi
}

function getProjectConfigurationId() {
    local projectId=$1
    local offeringName=$2
    local version=$3
    configId=$4

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

    # catalog/project configs are created and named as "offering name + version" then dots and spaces are translated to dashes
    configname=$(getConfigName "$offeringName" "$version")

    configId=$(ibmcloud project --project-id "$projectId" configs --output json | jq -r --arg configname "$configname" '.configs[] | select(.definition.name==$configname).id')

    if [[ $configId == "" ]]; then
        echo "project configuration with name $configname not found as expected.  exiting"
        exit 1
    fi
}

function getConfigName() {
    local offeringName=$1
    local version=$2

    configname=$(echo "${offeringName}""-""${version}" | tr '.' '-' | tr ' ' '-')
    echo "$configname"
}

function validateProjectConfig() {
    local projectId=$1
    local offeringName=$2
    local version=$3
    configId=$4

    # because we are using ys1 right now
    export PROJECT_URL=https://projects.api.test.cloud.ibm.com

    getProjectConfigurationId "$projectId" "$offeringName" "$version" "$configId"
    echo "project configuration id is: $configId"
   
    # update the project's config with values to use for validate/deploy.  Authorization method and value on the config is already set by catalog from the trusted profile setting on the catalog/project link up.
    echo "updating project configuration with values for validation"
    ibmcloud project config-update --project-id "$projectId"  --id "$configId" --input='[{"name": "prefix", "value":"epx-validate"}, {"name": "ssh_key", "value": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxsNM3xgeyU5pANw4r8qgiOMHktfj3z0/OSeIjscx2uCS4/loB/mRpG0+pgDctp1i+0AIh3wFPFUtdqzrR7otC1wo0Tmky6DT4E9yOoSO1nC413L2wDHyBtwp8mk+DhARXzeRdDvP0NtL+Rj1qy7OOAnZ0/Utu07dME8wEtOIotlGPZQmJvf78znV9eX9UU8A/J+IaC+0tK4W4Wt8irIc9kKm+3tcQsnpxmDgkApmwMjOcCH6yaONu1pYKAhBIzwkOTJl/VrEFeduPSdmL7ENtpITB0AZ99doYTucmQ73Axt728foXAFW8WX4uROc9df9Qyev40bxSzlAOGHvtEVwpNOqx6oAr1Kok811OITcuGtuUTDuPVXJyqBmWq2p9tMFrIFRN28lE5Ax3HYFinRaQ+X6rM1pIeHBA/ESS52lO5xpPl4k0laKWVeG42Ch8xi3ZjPk5Mg+AYMt9u9jtQ2KyZvV+zIO+jwlGXkiMSBWgm+7SnsJnRf+q2xg9cpXKjB0= kbiegert@Keiths-MacBook-Pro-2.local"}]'
    
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
    while [[ $attempts -le 240 ]] && [[ "$state" != "pipeline_failed" ]]
    do
        sleep 15
        state=$(ibmcloud project --project-id "$projectId" --id "$configId" config-get --output json | jq -r '.pipeline_state')
        echo "project config validation status: $state"
        attempts=$((attempts+1))
    done
}

function installProjectConfig() {
    local projectId=$1

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

function publishVersion() {
    local projectId=$1
    local offeringName=$2
    local version=$3

    configname=$(getConfigName "$offeringName" "$version")

    # get the catalog version locator for an offering version from the project config
    vl=$(ibmcloud project --project-id "$projectId" configs --output json | jq -r --arg configname "$configname" '.configs[] | select(.definition.name==$configname).definition.locator_id')

    # publish the new version
    ibmcloud catalog offering ready --version-locator "$vl"
}

function cleanUpResources() {
    local projectId=$1
    local configId=$2

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


# Notes:
#     - delete version from catalog initiates delete config at project
#     - project default settings are to delete everything if the project is deleted, this includes workspace and resources


# ------------------------------------------------------------------------------------
#  main
# ------------------------------------------------------------------------------------

# projectId=$1
# catalogName=$2
# offeringName=$3
# version=$4
# variationLabel=$5
# formatKind=$6
# installType=$7
# tarBall=$8

projectId="c99bc801-4cfc-45af-b626-bb6ffd6d2d30"
catalogName="Keith Test"
offeringName="custom-deployable-arch"
version="0.0.56"
variationLabel="BabySLZ"
formatKind="terraform"
installType="fullstack"
tarBall="https://github.com/IBM/customized-deployable-architecture/archive/refs/tags/0.0.56-epx.tar.gz"

configId=""

onboardVersionToCatalog "$tarBall" "$version" "$catalogName" "$offeringName" "$variationLabel" "$formatKind" "$installType"
validateProjectConfig "$projectId" "$offeringName" "$version" "$configId" 
installProjectConfig "$projectId" "$configId"
publishVersion "$projectId" "$offeringName" "$version"
cleanUpResources "$projectId" "$configId"

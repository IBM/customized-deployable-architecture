#! /bin/bash

#
# this function queries the cloud catalog and deterines the schematics workspace id of the workspace that was used  
# for validation of this version of the offering.
function getWorkspaceId() {
    local catalogName="$1"
    local offeringName="$2"
    local version="$3"
    local variationLabel="$4"
    local installType="$5"

    ibmcloud catalog offering get -c "$catalogName" -o "$offeringName" --output json | jq -r --arg version "$version" --arg variationLabel "$variationLabel" --arg installType "$installType" '.kinds[] | select(.format_kind=="terraform").versions[] | select(.version==$version) | select(.solution_info.install_type ==$installType) | select(.flavor.label==$variationLabel)  |.validation.target.workspace_id'
}

#
# this function queries the Schematics service to determine the status of the workspace's last job
function getWorkspaceStatus() {
    local workspaceStatus
    local workspaceId="$1"

    # make sure workspace is there - look for 404 status
    workspaceStatus=$(ibmcloud schematics workspace get --id "$workspaceId" --output json 2>/dev/null | grep -o 'statuscode:.*404')
    if [ ${#workspaceStatus} -eq 0 ] 
    then
        workspaceStatus=$(ibmcloud schematics workspace get --id "$workspaceId" --output json | jq -r '.status')
    else    
        workspaceStatus="NOTFOUND"
    fi

    echo "$workspaceStatus"
}

#
# this function queries the cloud catalog and deterines the schematics blueprint id of the blueprint that was used  
# for validation of this version of this offering.
function getBlueprintId() {
    local catalogName="$1"
    local offeringName="$2"
    local version="$3"
    local variationLabel="$4"
    local installType="$5"

    ibmcloud catalog offering get -c "$catalogName" -o "$offeringName" --output json | jq -r --arg version "$version" --arg variationLabel "$variationLabel" --arg installType "$installType" '.kinds[] | select(.format_kind=="blueprint").versions[] | select(.version==$version) | select(.solution_info.install_type ==$installType) | select(.flavor.label==$variationLabel) | .validation.target.blueprint_id'
}

#
# this function queries the Schematics service to determine the status of the blueprint 
function getBlueprintStatus() {
    local bp_status
    local blueprintId="$1"

    bp_status=$(ibmcloud schematics blueprint get --id "$blueprintId" --output json | jq -r '.state.run_status')
    attempts=0
    while [[ $attempts -le 240 ]] && [ "$bp_status" = "null" ]
    do
        sleep 15
        bp_status=$(ibmcloud schematics blueprint get --id "$blueprintId" --output json | jq -r '.state.run_status')
    done

    echo "$bp_status"
}
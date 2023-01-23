#! /bin/bash

#
# this function queries the cloud catalog and deterines the schematics workspace id of the workspace that was used  
# for validation of this version of the offering.
function getWorkspaceId() {
    ibmcloud catalog offering get -c "$CATALOG_NAME" -o "$OFFERING_NAME" --output json | jq -r --arg version "$VERSION" '.kinds[] | select(.format_kind=="terraform").versions[] | select(.version==$version).validation.target.workspace_id'
}

#
# this function queries the Schematics service to determine the status of the workspace's last job
function getWorkspaceStatus() {
    ibmcloud schematics workspace get --id "$WORKSPACE_ID" --output json | jq -r '.status'
}

#
# this function tells the Schematics service to delete a workspace and waits for it to delete 
# or fail to delete by exceeding the number of retries.  workspace delete should be a quick
# operation.
function deleteWorkspace() {
    local destroyStatus=$(getWorkspaceStatus)

    if [ "$destroyStatus" != "FAILED" ] && [ -n "$destroyStatus" ]
    then
        echo "delete workspace"
        local attempts=0
        local ret=1
        while [[ ret -ne 0 ]] && [[ $attempts -le 3 ]]
        do
            ret=0
            ibmcloud schematics workspace delete --id "$WORKSPACE_ID" -f || ret=$?
            if [[ ret -ne 0 ]]
            then
                attempts=$((attempts+1))
                echo "failure number ${attempts} to delete workspace"
                sleep 15
            fi
        done
    fi
}

#
# this function queries a schematics workspace until its resources have been destroyed (status is inactive) or 
# the destroy operation has failed or the destroy has taken too long and exceeded a time limit.
function queryAndWaitForWorkspace() {
    local attempts=0
    local counter=0
    local destroyStatus=incomplete
    while [ "$destroyStatus" != "INACTIVE" ] && [ "$destroyStatus" != "FAILED" ] && [[ $attempts -le 3 ]]
    do
        sleep 10
        counter=$((counter+1))
        if [[ counter -ge 30 ]]
        then
            echo "workspace resource destroy status: ${destroyStatus}"
            counter=0
        fi
        ret=0
        prevDestroyStatus="$destroyStatus"
        destroyStatus=$(getWorkspaceStatus) || ret=$?
        if [[ ret -ne 0 ]]
        then
            attempts=$((attempts+1))
            echo "failure number ${attempts} when attempting to check workspace resource destroy status"
        fi
        if [ "$prevDestroyStatus" != "$destroyStatus" ]
        then
            echo "workspace resource destroy status: ${destroyStatus}"
        fi
    done
}

#
# this function destroys the resources associated to a workspace.  the workspace is the workspace that was used for the validation
# operation for the offering version.
function destroyWorkspaceResources() {
    # refresh token
    ibmcloud catalog utility netrc

    # get the schematics workspace id of the workspace that was used for the validation of this version
    WORKSPACE_ID=$(getWorkspaceId)

    echo "workspace id: $WORKSPACE_ID"
    workspaceStatus=$(getWorkspaceStatus)
    echo "workspace status: ${workspaceStatus}"

    if [ "$workspaceStatus" != "INACTIVE" ]
    then
        echo "destroying workspace resources"
        ibmcloud schematics destroy --id "$WORKSPACE_ID" -f

        echo "waiting for resources to be destroyed"
        # wait for destroy workspace to be started
        attempts=0
        destroyStarted=$(getWorkspaceStatus)
        while [ "$destroyStarted" != "INPROGRESS" ] && [[ $attempts -le 60 ]]
        do
            sleep 5
            destroyStarted=$(getWorkspaceStatus)
            attempts=$((attempts+1))
            if [[ attempts -ge 30 ]]
            then
                echo "workspace status: ${destroyStatus} . failed to start destroy after 5 minutes.  giving up."
                exit 1
            fi
        done
        echo "workspace destroy resources started"

        queryAndWaitForWorkspace
        destroyStatus=$(getWorkspaceStatus)
        
        # max attempts reached or the resource destroy failed.  try to destroy again.
        if [ "$destroyStatus" == "FAILED" ]
        then
            echo "workspace resource destroy failed - retrying"
            queryAndWaitForWorkspace
        fi
    fi

    destroyStatus=$(getWorkspaceStatus)
    echo "final resource destroy status: ${destroyStatus}"
}

#
# this function queries the cloud catalog and deterines the schematics blueprint id of the blueprint that was used  
# for validation of this version of this offering.
function getBlueprintId() {
    ibmcloud catalog offering get -c "$CATALOG_NAME" -o "$OFFERING_NAME" --output json | jq -r --arg version "$VERSION" '.kinds[] | select(.format_kind=="blueprint").versions[] | select(.version==$version).validation.target.blueprint_id'
}

#
# this function queries the Schematics service to determine the status of the blueprint 
function getBlueprintStatus() {
    ibmcloud schematics blueprint get --id "$BLUEPRINT_ID" --output json | jq -r '.state.run_status'
}

#
# this function destroys the resources associated with a blueprint which will be in multiple workspaces.
# 
function destroyBlueprintResources() {
    # refresh token
    ibmcloud catalog utility netrc

    # get the schematics workspace id of the workspace that was used for the validation of this version
    BLUEPRINT_ID=$(getBlueprintId)

    echo "blueprint id: $BLUEPRINT_ID"
    blueprintStatus=$(getBlueprintStatus)
    echo "blueprint status: ${blueprintStatus}"

    # this command self blocks until the destroy is finished
    echo "destroying blueprint resources"
    ibmcloud schematics blueprint destroy --id $BLUEPRINT_ID --no-prompt
}

#
# this function deletes the workspaces associated to a blueprint and the blueprint itself.
#
function deleteBlueprint() {

    # this command submits a schematics job to delete the individual workspaces and the blueprint
    ibmcloud schematics blueprint delete --id $BLUEPRINT_ID --no-prompt

    # let the delete finish
    sleep 15 

    echo "blueprint and workspaces delete started."
}

#
# destroy resources created by either a terraform or blueprint
function destroyResources() {
    if [ "$FORMAT_KIND" = "terraform" ]
        then destroyWorkspaceResources
        else destroyBlueprintResources
    fi
}

# 
# delete workspaces and blueprints
function deleteWorkspaces() {
    if [ "$FORMAT_KIND" = "terraform" ]
        then deleteWorkspace
        else deleteBlueprint
    fi    
}

# ------------------------------------------------------------------------------------
#  main
# ------------------------------------------------------------------------------------

CATALOG_NAME=$1
OFFERING_NAME=$2
VERSION=$3
FORMAT_KIND=$4

echo "cleaning up workspaces, resources"

destroyResources
deleteWorkspaces
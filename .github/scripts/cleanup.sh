#! /bin/bash

#
# this function queries the cloud catalog and deterines the schematics workspace id of the workspace that was used  
# for validation.
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
# this function destroys a workspace and its resources.  the workspace is the workspace that ws used for the validation
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
            if [[ counter -ge 30 ]]
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

# ------------------------------------------------------------------------------------
#  main
# ------------------------------------------------------------------------------------

CATALOG_NAME=$1
OFFERING_NAME=$2
VERSION=$3

echo "cleaning up workspace and resources"

destroyWorkspaceResources
deleteWorkspace
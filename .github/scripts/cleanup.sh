#! /bin/bash

#
# this function tells the Schematics service to delete a workspace and waits for it to delete 
# or fail to delete by exceeding the number of retries.  workspace delete should be a quick
# operation.
function deleteWorkspace() {
    local catalogName="$1"
    local offeringName="$2"
    local version="$3"
    local variationLabel="$4"
    local installType="$5"
    local workspaceId
    local deleteStatus
    
    workspaceId=$(getWorkspaceId "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType")

    deleteStatus=$(getWorkspaceStatus "$workspaceId")

    if [ "$deleteStatus" != "FAILED" ] && [ -n "$deleteStatus" ]
    then
        echo "delete workspace"
        local attempts=0
        local ret=1
        while [[ ret -ne 0 ]] && [[ $attempts -le 3 ]] && [[ $deleteStatus != "NOTFOUND" ]]
        do
            ret=0
            ibmcloud schematics workspace delete --id "$workspaceId" -f || ret=$?
            if [[ ret -ne 0 ]]
            then
                attempts=$((attempts+1))
                echo "failure number ${attempts} to delete workspace"
                sleep 15

                # update status 
                deleteStatus=$(getWorkspaceStatus "$workspaceId")
            fi
        done
    fi
}

#
# this function queries a schematics workspace until its resources have been destroyed (status is inactive) or 
# the destroy operation has failed or the destroy has taken too long and exceeded a time limit.
function queryAndWaitForWorkspace() {
    local workspaceId=$1
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
        destroyStatus=$(getWorkspaceStatus "$workspaceId") || ret=$?
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
    local catalogName="$1"
    local offeringName="$2"
    local version="$3"
    local variationLabel="$4"
    local installType="$5"
    local workspaceId

    # refresh token
    ibmcloud iam oauth-tokens
    ibmcloud catalog utility netrc

    # get the schematics workspace id of the workspace that was used for the validation of this version
    workspaceId=$(getWorkspaceId "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType")

    echo "workspace id: $workspaceId"
    workspaceStatus=$(getWorkspaceStatus "$workspaceId")
    echo "workspace status: ${workspaceStatus}"

    if [ "$workspaceStatus" != "INACTIVE" ]
    then
        echo "destroying workspace resources"
        ibmcloud schematics destroy --id "$workspaceId" -f

        echo "waiting for resources to be destroyed"
        # wait for destroy workspace to be started
        attempts=0
        destroyStarted=$(getWorkspaceStatus "$workspaceId")
        while [ "$destroyStarted" != "INPROGRESS" ] && [[ $attempts -le 60 ]]
        do
            sleep 5
            destroyStarted=$(getWorkspaceStatus "$workspaceId")
            attempts=$((attempts+1))
            if [[ attempts -ge 30 ]]
            then
                echo "workspace status: ${destroyStatus} . failed to start destroy after 5 minutes.  giving up."
                exit 1
            fi
        done
        echo "workspace destroy resources started"

        queryAndWaitForWorkspace "$workspaceId"
        destroyStatus=$(getWorkspaceStatus "$workspaceId")
        
        # max attempts reached or the resource destroy failed.  try to destroy again.
        if [ "$destroyStatus" = "FAILED" ]
        then
            echo "workspace resource destroy failed - retrying"
            queryAndWaitForWorkspace "$workspaceId"
        fi
    fi

    destroyStatus=$(getWorkspaceStatus "$workspaceId")
    echo "final resource destroy status: ${destroyStatus}"
}

#
# this function destroys the resources associated with a blueprint which will be in multiple workspaces.
# 
function destroyBlueprintResources() {
    local catalogName="$1"
    local offeringName="$2"
    local version="$3"
    local variationLabel="$4"
    local installType="$5"
    local blueprintId

    # refresh token
    ibmcloud iam oauth-tokens
    ibmcloud catalog utility netrc

    # get the schematics workspace id of the workspace that was used for the validation of this version
    blueprintId=$(getBlueprintId "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType")

    echo "destroying blueprint resources for blueprint id: $blueprintId"
    blueprintStatus=$(getBlueprintStatus "$blueprintId")
    echo "blueprint status: ${blueprintStatus}"

    # allow the status of the blueprint in schematics to fully update after the apply - wait up to two minutes
    attempts=0
    while [ "$blueprintStatus" != "RUN_APPLY_COMPLETE" ] && [[ $attempts -le 24 ]]
    do
        sleep 5
        blueprintStatus=$(getBlueprintStatus)
        attempts=$((attempts+1))
        if [[ attempts -ge 24 ]]
        then
            echo "blueprint status: ${blueprintStatus} . Blueprint failed to be completely applied after 2 minutes.  giving up."
            exit 1
        fi
    done 

    # this command self blocks until the destroy is finished
    echo "destroying blueprint resources"
    ibmcloud schematics blueprint destroy --id "$blueprintId" --no-prompt
}

#
# this function deletes the workspaces associated to a blueprint and the blueprint itself.
#
function deleteBlueprint() {
    local catalogName="$1"
    local offeringName="$2"
    local version="$3"
    local variationLabel="$4"
    local installType="$5"
    local blueprintId

    ibmcloud iam oauth-tokens

    # get the schematics workspace id of the workspace that was used for the validation of this version
    blueprintId=$(getBlueprintId "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType")

    echo "deleting blueprint and workspaces for blueprint id: $blueprintId"
    blueprintStatus=$(getBlueprintStatus "$blueprintId")
    echo "blueprint status: ${blueprintStatus}"

    # allow the status of the blueprint in schematics to fully update after the destroy - wait up to two minutes
    attempts=0
    while [ "$blueprintStatus" != "RUN_DESTROY_COMPLETE" ] && [[ $attempts -le 24 ]]
    do
        sleep 5
        blueprintStatus=$(getBlueprintStatus)
        attempts=$((attempts+1))
        if [[ attempts -ge 24 ]]
        then
            echo "blueprint status: ${blueprintStatus} . Blueprint modules failed to show destroyed.  giving up."
            exit 1
        fi
    done

    ibmcloud iam oauth-tokens

    # this command submits a schematics job to delete the individual workspaces and the blueprint
    ibmcloud schematics blueprint delete --id "$blueprintId" --no-prompt

    # let the delete finish
    sleep 60

    echo "blueprint and workspaces delete requested."
}

#
# destroy resources created by either a terraform or blueprint
function destroyResources() {
    local catalogName="$1"
    local offeringName="$2"
    local version="$3"
    local variationLabel="$4"
    local installType="$5"
    local formatKind="$6"

    if [ "$formatKind" = "terraform" ]
        then destroyWorkspaceResources "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType"
        else destroyBlueprintResources "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType"
    fi
}

# 
# delete workspaces and blueprints
function deleteWorkspaces() {
    local catalogName="$1"
    local offeringName="$2"
    local version="$3"
    local variationLabel="$4"
    local installType="$5"
    local formatKind="$6"

    if [ "$formatKind" = "terraform" ]
        then deleteWorkspace "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType"
        else deleteBlueprint "$catalogName" "$offeringName" "$version" "$variationLabel" "$installType"
    fi    
}

# ------------------------------------------------------------------------------------
#  main
# ------------------------------------------------------------------------------------

CATALOG_NAME="$1"
OFFERING_NAME="$2"
VERSION="$3"
VARIATION_LABEL="$4"
INSTALL_TYPE="$5"
FORMAT_KIND="$6"

# ensure we are still logged in
ibmcloud login --apikey "$IBMCLOUD_API_KEY" --no-region

echo "cleaning up workspaces, resources for: $OFFERING_NAME, version $VERSION, install type $INSTALL_TYPE format kind $FORMAT_KIND"

source ./.github/scripts/common-functions.sh

destroyResources "$CATALOG_NAME" "$OFFERING_NAME" "$VERSION" "$VARIATION_LABEL" "$INSTALL_TYPE" "$FORMAT_KIND"
deleteWorkspaces "$CATALOG_NAME" "$OFFERING_NAME" "$VERSION" "$VARIATION_LABEL" "$INSTALL_TYPE" "$FORMAT_KIND"
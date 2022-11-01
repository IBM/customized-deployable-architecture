#! /bin/bash

VERSION=$(echo ${{ github.event.release.tag_name }})
CATALOG_NAME=$1
OFFERING_NAME=$2

# get the schematics workspace id that was used for the validation of this version
WORKSPACE_ID=$(ibmcloud catalog offering get -c "$CATALOG_NAME" -o "$OFFERING_NAME" --output json | jq -r --arg version "$VERSION" '.kinds[] | select(.format_kind=="terraform").versions[] | select(.version==$version).validation.target.workspace_id')

echo "refreshing token and netrc"
ibmcloud catalog utility netrc

echo "workspace id: $WORKSPACE_ID"
workspaceStatus=$(ibmcloud schematics workspace get --id "$WORKSPACE_ID" --output json | jq -r '.status')
echo "workspace status: ${workspaceStatus}"

if [ "$workspaceStatus" != "INACTIVE" ]
then
    echo "destroying workspace resources"
    ibmcloud schematics destroy --id "$WORKSPACE_ID" -f

    echo "waiting for resources to be destroyed"
    sleep 5
    attempts=0
    counter=0
    destroyStatus=incomplete
    while [ "$destroyStatus" != "COMPLETED" ] && [ "$destroyStatus" != "FAILED" ] && [[ $attempts -le 3 ]]
    do
        sleep 10
        counter=$((counter+1))
        if [[ counter -ge 30 ]]
        then
            echo "destroy status: ${destroyStatus}"
            counter=0
        fi
        ret=0
        prevDestroyStatus="$destroyStatus"
        destroyStatus=$(ibmcloud schematics workspace action --id "$WORKSPACE_ID" --output json | jq -r '[.actions[] | select(.name=="DESTROY").status][0]') || ret=$?
        if [[ ret -ne 0 ]]
        then
            attempts=$((attempts+1))
            echo "failure number ${attempts} to check destroy status"
        fi
        if [ "$prevDestroyStatus" != "$destroyStatus" ]
        then
            echo "destroy status: ${destroyStatus}"
        fi
    done
    if [ "$destroyStatus" == "FAILED" ]
    then
        echo "destroy failed- retrying"
        attempts=0
        counter=0
        destroyStatus=incomplete
        while [ "$destroyStatus" != "COMPLETED" ] && [ "$destroyStatus" != "FAILED" ] && [[ $attempts -le 3 ]]
        do
            sleep 10
            counter=$((counter+1))
            if [[ counter -ge 30 ]]
            then
                echo "destroy status: ${destroyStatus}"
                counter=0
            fi
            ret=0
            prevDestroyStatus="$destroyStatus"
            destroyStatus=$(ibmcloud schematics workspace action --id "$WORKSPACE_ID" --output json | jq -r '[.actions[] | select(.name=="DESTROY").status][0]') || ret=$?
            if [[ ret -ne 0 ]]
            then
                attempts=$((attempts+1))
                echo "failure number ${attempts} to check destroy status"
            fi
            if [ "$prevDestroyStatus" != "$destroyStatus" ]
            then
                echo "destroy status: ${destroyStatus}"
            fi
        done
    fi
fi

echo "final destroy status: ${destroyStatus}"

if [ "$destroyStatus" != "FAILED" ] && [ -n "$destroyStatus" ]
then
    echo "delete workspace"
    attempts=0
    ret=1
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
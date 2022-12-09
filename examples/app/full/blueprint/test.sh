#!/bin/bash

# set -x

## This script will create this blueprint on schematics using the CLI and jq.  
## The script assume that:
##   o CLI is logged in
##   o env variable APIKEY is set with your cloud APIKEY
##   o env variable SSHKEY is set with your SSH Key to providion a VSI with

export inFile="$1"
export BlueprintName="${BlueprintName:-"appache app blueprint"}"
export Location="${Location:-us-east}"
export ResourceGroup="${ResourceGroup:-Default}"

if [ -z "$APIKEY" -o -z "$SSHKEY" ]; then
   echo "Environment with SSHKEY and APIKEY is not set"
   exit 1
fi

if [ -z "$inFile" ]; then
   export inFile="inputs-full.json"
fi

export tmpFile="/tmp/in.json"
envsubst < $inFile > $tmpFile

ibmcloud target -r "$Location" -g "$ResourceGroup"

echo "Creating Blueprint: \"$BlueprintName\" using Inputfile: \"$inFile\" and resource group ID: \"$ResourceGroup\""
ibmcloud schematics blueprint config create -f "${tmpFile}"

bpID=$(ibmcloud schematics blueprint list --output json | jq --arg BlueprintName "$BlueprintName" -r '.blueprints[]  | select(.name == $BlueprintName) | .id')

if [ -z "$bpID" ]; then
    echo "Blueprint \"$BlueprintName\" not found"
    exit 1
fi

echo "Applying Blueprint: $bpID"
ibmcloud schematics blueprint run apply -i "${bpID}"

echo -e "To delete:\n\tibmcloud schematics blueprint run destroy --no-prompt -i ${bpID}\n\tibmcloud schematics blueprint config delete -fd -i ${bpID}"

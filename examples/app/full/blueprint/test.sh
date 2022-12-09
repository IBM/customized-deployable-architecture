#!/bin/bash

# set -x

## This script will create this blueprint on schematics using the CLI and jq.  
## The script assume that:
##   o CLI is logged in
##   o env variable APIKEY is set with your cloud APIKEY
##   o env variable SSHKEY is set with your SSH Key to providion a VSI with
##   You can optionally set a "inFile" to specify wich blueprint to sumbit, and a "Prefix" to override the default one

export inFile="$1"
export BlueprintName="${BlueprintName:-"Apache Web Server blueprint"}"
export Location="${Location:-us-east}"
export ResourceGroup="${ResourceGroup:-Default}"
export Prefix="${Prefix:-aa-tst}"

if [ -z "$APIKEY" -o -z "$SSHKEY" ]; then
   echo "Environment with SSHKEY and APIKEY is not set"
   exit 1
fi

if [ -z "$inFile" ]; then
   export inFile="inputs-template.json"
fi

if [ -z "$Prefix" ] ; then
   export Prefix="aa-tst"
fi

export tmpFile="/tmp/in.json"
envsubst < $inFile > $tmpFile

ibmcloud target -r "$Location" -g "$ResourceGroup"

echo -e "Creating Blueprint: \"$BlueprintName\"\n\tInputfile: \"$inFile\"\n\tResource Group: \"$ResourceGroup\"\n\tPrefix: \"$Prefix\""
ibmcloud schematics blueprint config create -f "${tmpFile}"

bpID=$(ibmcloud schematics blueprint list --output json | jq --arg BlueprintName "$BlueprintName" -r '.blueprints[]  | select(.name == $BlueprintName) | .id')

if [ -z "$bpID" ]; then
    echo "Blueprint \"$BlueprintName\" not found"
    exit 1
fi

echo "Applying Blueprint: $bpID"
ibmcloud schematics blueprint run apply -i "${bpID}"

echo -e "To delete:\n\tibmcloud schematics blueprint run destroy --no-prompt -i ${bpID}\n\tibmcloud schematics blueprint config delete -fd -i ${bpID}"

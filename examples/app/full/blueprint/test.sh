#!/bin/bash

## This script will create this blueprint on schematics using the CLI and jq.  
## The script assume that:
##   o CLI is logged in
##   o env variable APIKEY is set with your cloud APIKEY
##   o env variable SSHKEY is set with your SSH Key to providion a VSI with

export inFile="/tmp/in.json"
export Name="TEST: appache app blueprint"

cat > $inFile <<EOF
{
    "name": "${Name}",
    "tags": [
        "aa-test"
    ],
    "source": {
        "source_type": "git_hub",
        "git": {
            "git_repo_url": "https://github.com/IBM/customized-deployable-architecture",
            "git_repo_folder": "/examples/app/full/blueprint/full.yaml",
            "git_branch": "main"
        }
    },
    "inputs": [
        {
            "name": "ibmcloud_api_key",
            "value": "${APIKEY}"
        },
        {
            "name": "prefix",
            "value": "tst"
        },
        {
            "name": "ssh_key",
            "value": "${SSHKEY}"
        }
    ],
    "description": "TEST: deployable architecture blueprint",
    "resource_group": "Default",
    "location": "us-south"
}
EOF

echo "Creating Blueprint: \"$Name\" using Inputfile: $inFile"
ibmcloud schematics blueprint config create -f "${inFile}"

bpID=$(ic schematics blueprint list --output json | jq -r ".blueprints[]  | select(.name == \"${Name}\") | .id")

echo "Starting Blueprint: $bpID"
ibmcloud  schematics blueprint run apply -i "${bpID}"

echo -e "To delete:\n\tic schematics blueprint config delete -i "${bpID}"


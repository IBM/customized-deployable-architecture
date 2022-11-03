#! /bin/bash

VALIDATION_VALUES=$1

# generate an ssh key that can be used as a validation value 
ssh-keygen -f ./id_rsa -t rsa -N ''
SSH_KEY=$(cat ./id_rsa.pub)

# format offering validation values into json format
jq -n --arg IBMCLOUD_API_KEY "$IBMCLOUD_API_KEY" --arg SSH_KEY "$SSH_KEY" '{ "ibmcloud_api_key": $IBMCLOUD_API_KEY, "prefix": "validation", "ssh_key": $SSH_KEY }' > "$VALIDATION_VALUES"

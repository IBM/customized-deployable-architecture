#! /bin/bash

# run the ibmcloud cli installer
curl -sL https://ibm.biz/idt-installer | bash

# run the ibmcloud cli and install needed plugins
ibmcloud plugin install catalogs-management
ibmcloud plugin install schematics
ibmcloud plugin install project
ibmcloud plugin install vpc-infrastructure
ibmcloud plugin install security-compliance

# list whats installed into the log
ibmcloud plugin list

# login to the IBM Cloud using an api key from the appropriate cloud account
ibmcloud login --apikey "$IBMCLOUD_API_KEY" --no-region
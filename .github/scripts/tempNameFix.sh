#! /bin/bash

# This is a very temporary workaround for an issue that is due to be fixed at the end of Jan 2023.
# Once the fix for that issue is delivered, this script will be removed. 

CATALOG_NAME=$1
OFFERING_NAME=$2

# get the offering from the catalog
ibmcloud catalog offering get --catalog "$CATALOG_NAME" --offering "$OFFERING_NAME" --output json > demo.json

# change the variation display name to the desired name in the offering json
cat demo.json | sed 's/\"label\": \"BP-Standard\",/\"label\": \"Standard\",/' > demo-new.json

# update the catalog 
ibmcloud catalog offering update --catalog "$CATALOG_NAME" --offering "$OFFERING_NAME" --updated-offering demo-new.json
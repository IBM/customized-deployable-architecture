#! /bin/bash

#
# To use the same DA in ys1 cloud, there a just a few changes to be made.  To use this script
#   1.  create a new branch from main
#   2.  be in the root directory of the repo directory tree
#   3.  run this script
# Keep the main branch up to date as per usual.  Create a fresh test branch periodically by running this script
# and create a test release from this branch.  This way dual maintenance is not needed on two branches.
#
# The script changes:
# - in the custom-slz DA, change 'us-east' to 'us-south'
# - in the ibm_catalog.json file, set the programmatic name to 'deploy-arch-ibm-gm-test-slz' to prevent a name 
#   collision with 'custom-deployable-arch' AND set the label to 'Test SLZ'.
#

echo "Making changes to BabySLZ variation enable successfull deployment on ys1"

cd solutions/custom-slz || exit

echo "...modify main.tf"
echo ".....change region from us-east to us-south"
sed -i '' 's/us-east/us-south/g' main.tf

cd ../..
echo "...modify ibm_catalog.json"
echo ".....change \"name\": \"custom-deployable-arch\" to \"name\": \"deploy-arch-ibm-gm-test-slz\""
sed -i '' 's/name\": \"custom-deployable-arch/name\": \"deploy-arch-ibm-gm-test-slz/g' ibm_catalog.json

echo ".....change \"label\": \"custom-deployable-arch\" to \"label\": \"Test SLZ\""
sed -i '' 's/label\": \"custom-deployable-arch/label\": \"Test SLZ/g' ibm_catalog.json

echo "done with changes."
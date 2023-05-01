#! /bin/bash

echo "Making changes to BabySLZ variation enable successfull deployment on ys1"

cd solutions/custom-deployable-arch/babyslz || exit

echo "...modify main.tf"
echo ".....change us-east to us-south"
echo ".....change source reference url in main.tf"
../../../.github/scripts/ys1/main-tf-changes.awk < main.tf > main.tf.new
cp main.tf.new main.tf
rm main.tf.new

echo "...modify override.json"
echo ".....change slz-service-rg to Default"
echo ".....change slz-workload-rg to Default"
echo ".....change resource group create settings in override.json"
../../../.github/scripts/ys1/override-json-changes.awk < override.json > override.json.new
cp override.json.new override.json
rm override.json.new

echo "done with changes."
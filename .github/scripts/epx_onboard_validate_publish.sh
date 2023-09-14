#! /bin/bash

projectId="098fe711-1378-4514-bc22-baf0153093c7"
catalogName="Keith Test"
offeringName="custom-deployable-arch"
version="0.0.56"
variationLabel="BabySLZ"
formatKind="terraform"
installType="fullstack"
tarBall="https://github.com/IBM/customized-deployable-architecture/archive/refs/tags/0.0.55-epx.tar.gz"


# onboard to catalog
ibmcloud catalog offering import-version --zipurl "$tarBall" --target-version "$version" --catalog "$catalogName" --offering "$offeringName" --variation-label "$variationLabel" --format-kind "$formatKind" --install-type "$installType"

export PROJECT_URL=https://projects.api.test.cloud.ibm.com

# list the project configs and find the one created by catalog onboard.  the one we want is named "<offering-name>-<semver>" where dashes replace dots in semver
ibmcloud project --project-id $projectId configs

# catalog/project configs are created and named as "offering name + version" then dots and spaces are translated to dashes
configname=$(echo ${offeringName}"-"${version} | tr '.' '-')
configId=$(ibmcloud project --project-id $projectId configs --output json | jq -r --arg configname "$configname" '.configs[] | select(.definition.name==$configname).id')

# update the project's config with values to use for validate/deploy.  Authorization method and value on the config is already set by catalog from the trusted profile setting on the catalog/project link up.
ibmcloud project config-update --project-id "$projectId"  --id "$configId" --input='[{"name": "prefix", "value":"epx-validate"}, {"name": "ssh_key", "value": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxsNM3xgeyU5pANw4r8qgiOMHktfj3z0/OSeIjscx2uCS4/loB/mRpG0+pgDctp1i+0AIh3wFPFUtdqzrR7otC1wo0Tmky6DT4E9yOoSO1nC413L2wDHyBtwp8mk+DhARXzeRdDvP0NtL+Rj1qy7OOAnZ0/Utu07dME8wEtOIotlGPZQmJvf78znV9eX9UU8A/J+IaC+0tK4W4Wt8irIc9kKm+3tcQsnpxmDgkApmwMjOcCH6yaONu1pYKAhBIzwkOTJl/VrEFeduPSdmL7ENtpITB0AZ99doYTucmQ73Axt728foXAFW8WX4uROc9df9Qyev40bxSzlAOGHvtEVwpNOqx6oAr1Kok811OITcuGtuUTDuPVXJyqBmWq2p9tMFrIFRN28lE5Ax3HYFinRaQ+X6rM1pIeHBA/ESS52lO5xpPl4k0laKWVeG42Ch8xi3ZjPk5Mg+AYMt9u9jtQ2KyZvV+zIO+jwlGXkiMSBWgm+7SnsJnRf+q2xg9cpXKjB0= kbiegert@Keiths-MacBook-Pro-2.local"}]'

# validate via projects.  this only starts the job.  need to poll to get status
ibmcloud project --project-id $projectId --id "$configId" config-check

# wait and poll until state is "pipeline_failed" for now.  fails due to SCC.  look for state when SCC passes also
do while state!="pipeline_failed"
    wait(10 seconds)
    state=$(ibmcloud project --project-id $projectId --id "$configId" config-get --output json | jq -r '.pipeline_state')


# eventually do a force approve to get past failed SCC
ibmcloud project --project-id $projectId --id "$configId" --comment "cli pipeline" force-approve

# run a projects deploy
ibmcloud project --project-id $projectId --id "$configId" config-install

# wait and poll until state is "installed"
do while state=="installing"
    wait(10 seconds)
    state=$(ibmcloud project --project-id $projectId --id "$configId" config-get --output json | jq -r '.state')

# state now should ideally be "installed" - catalog version will automatically get marked then as "validated" 

# cleanup 
ibmcloud project --project-id $projectId --id "$configId" config-uninstall

do while state != "not_installed"
    wait(10 seconds)
    state=$(ibmcloud project --project-id $projectId --id "$configId" config-get --output json | jq -r '.state')

# get the catalog version locator for an offering version
ibmcloud catalog offering get --catalog "$catalogName" --offering "$offeringName" --output json > offering.json
versionLocator=$(jq -r --arg version "${version}" --arg variationLabel "${variationLabel}" --arg installType "${installType}" --arg format_kind "$formatKind" '.kinds[] | select(.format_kind==$format_kind).versions[] | select(.version==$version) | select(.solution_info.install_type == $installType) | select(.flavor.label==$variationLabel).version_locator' < offering.json)
# publish the new version
ibmcloud catalog offering ready --version-locator $versionLocator

# delete the validation workspace and resources? - insert code to get workspace id used for the projects deploy
ibmcloud schematics ws delete -id $workspaceId

Notes:
    - delete version from catalog initiates delete config at project
    - project default settings are to delete everything if the project is deleted, this includes workspace and resources
#! /bin/bash

# Steps to perform a scan
# 1. login to the IBM Cloud with the account that owns the an instance of IBM SCC
# 2. determine the id of the Security and Compliance profile that was given by name
# 3. create a new attachment for the profile
# 4. initiate an ondemand scan for the attachment against the resources deployed
# 5. wait for the scan to complete by querying its status
# 6. apply the scan results to the onboarded version of the offering
# 7. clean up by deleting the attachment that was created
#

# inputs:
#   SCC_PROFILE_NAME: the name of the compliance profile as found in IBM Security and Compliance. 
#   SCC_PROFILE_VERSION: the version of the profile.
#   SCC_ACCOUNT_ID: the IBM Cloud account id that owns the instance of SCC to use for scanning AND it is the account that owns the resources to be scanned.
#   SCC_INSTANCE_ID: the SCC instance id to use for scanning.
#   SCC_REGION: the IBM Cloud region where the SCC instance is located.
#   VERSION_LOCATOR: the catalog version locator value for this version of the offering. 
#
SCC_PROFILE_NAME="${1}"
SCC_PROFILE_VERSION="${2}"
SCC_ACCOUNT_ID="${3}"
SCC_INSTANCE_ID="${4}"
SCC_REGION="${5}"
VERSION_LOCATOR="${6}"

if [[ -z "${SCC_PROFILE_NAME}" || -z "${SCC_PROFILE_VERSION}" || -z "${SCC_ACCOUNT_ID}" || -z "${SCC_INSTANCE_ID}" || -z "${SCC_REGION}" || -z "${VERSION_LOCATOR}" ]]; then
    echo "Missing input parameter."
    echo "   usage: perform-sccv3-scan SCC_PROFILE_NAME SCC_PROFILE_VERSION SCC_ACCOUNT_ID SCC_INSTANCE_ID SCC_REGION VERSION_LOCATOR"
    echo "Exiting"
    exit 1
fi

#
# required ENV variables:
#   CATALOG_API_KEY - used to login to the IBM Cloud to query/update a catalog in this account.
#   SCC_API_KEY - used to query and configure an instance of IBM SCC owned by this account.
#
if [[ -z "${CATALOG_API_KEY}" ]]; then
    echo "Environment variable CATALOG_API_KEY is not set. Exiting."
    exit 1
fi

if [[ -z "${SCC_API_KEY}" ]]; then
    echo "Environment variable SCC_API_KEY is not set. Exiting."
    exit 1
fi

# constants 
MAX_SCAN_SECONDS=5400      # 90 mins for maximum time for scan to complete
SCAN_QUERY_WAIT=30         # seconds between queries to determin scan status
MAX_SCAN_QUERY_RETRIES=10  # max numober of times to retry getting scan status

# -----------------------------------------------------------------------------------------
# step 1 - login to the Cloud account that owns the instance of SCC
# -----------------------------------------------------------------------------------------
echo "Logging CLI into SCC owning account."
ibmcloud login --apikey "${SCC_API_KEY}" --no-region

# set the SCC endpoint by using the 
export SECURITY_AND_COMPLIANCE_CENTER_API_URL=https://$SCC_REGION.compliance.cloud.ibm.com/instances/$SCC_INSTANCE_ID/v3
echo "The SCC endpoint has been set to $SECURITY_AND_COMPLIANCE_CENTER_API_URL"

# -----------------------------------------------------------------------------------------
# step 2 - determine the id of the Security and Compliance profile that was given by name
# -----------------------------------------------------------------------------------------
PROFILE_LIST_JSON=$(ibmcloud scc profile list --output json)
if [[ -z "$PROFILE_LIST_JSON" || $? != 0 ]]; then
    echo "Unable to list SCC profiles. Exiting."
    exit 1
fi

# determine the profile id from the list 
PROFILE_ID=$(echo "${PROFILE_LIST_JSON}" | jq -r --arg SCC_PROFILE_NAME "${SCC_PROFILE_NAME}" --arg SCC_PROFILE_VERSION "${SCC_PROFILE_VERSION}" '.profiles[] | select(.profile_name==$SCC_PROFILE_NAME and .profile_version==$SCC_PROFILE_VERSION) | {id}' | jq -r .id)
if [[ -z "$PROFILE_ID" ]]; then
    echo "Profile ID not found for the profile named ${SCC_PROFILE_NAME} and version $SCC_PROFILE_VERSION .  Exiting"
    exit 1
fi

echo "SCC profile id is $PROFILE_ID for profile ${SCC_PROFILE_NAME} and version $SCC_PROFILE_VERSION"

# ----------------------------------------------------------------------------------------- 
# step 3 - create a new attachment for the profile and determine its id 
#    multiple steps needed as required by SCC to create an attachment
#    3.1 - query the SCC profile and retrieve the default parameters of the profile
#    3.2 - create the attachment using the default parameters from the profile
# -----------------------------------------------------------------------------------------

# query the SCC profile and retrieve the default parameters of the profile
PROFILE_JSON=$(ibmcloud scc profile get --profile-id "$PROFILE_ID" --output json)
if [[ -z "$PROFILE_JSON" || $? != 0 ]]; then
    echo "Unable to query the SCC profile $PROFILE_ID to determine attachment defaults. Exiting."
    exit 1
fi

# extract from the profile all of the default parameters ignoring everything else.  remove the default value settings.
DEFAULT_PROFILE_PARMS_JSON=$(echo "${PROFILE_JSON}" | jq -r '[.default_parameters[] | .["parameter_value"] = .parameter_default_value | del(.parameter_default_value)]')
if [[ -z "$DEFAULT_PROFILE_PARMS_JSON" ]]; then
    echo "Default SCC profile parameters were not found for the profile named $SCC_PROFILE_NAME , version $SCC_PROFILE_VERSION and id.  Exiting."
    exit 1
fi

# create the attachment using the default parameters from the profile
ATTACHMENT_NAME="github-action-$(date +%Y%m%d%H%M%S)"
CREATE_JSON=$(ibmcloud scc attachment create --profile-id "$PROFILE_ID" --attachments='[{"name": "'"$ATTACHMENT_NAME"'", "description": "created during github action to onboard DA", "status": "disabled", "scope":[{"environment":"ibm-cloud","properties":[{"name":"scope_id","value":"'"$SCC_ACCOUNT_ID"'"},{"name":"scope_type","value":"account"}]}], "attachment_parameters": '"${DEFAULT_PROFILE_PARMS_JSON}"'}]' --output json)
if [[ -z "$CREATE_JSON" || $? != 0 ]]; then
    echo "Unable to create an SCC attachment on profile $SCC_PROFILE_NAME .  Exiting."
    exit 1
fi

# determine the attachment id
ATTACH_ID=$(echo "${CREATE_JSON}" | jq -r '.attachments[0].id')
if [[ -z "${ATTACH_ID}" || "${ATTACH_ID}" == "null" ]]; then
    echo "Unable to determine the attachement id for attachment $ATTACHMENT_NAME on profile ${SCC_PROFILE_NAME} . Exiting."
    exit 1
fi

echo "SCC attachment id is ${ATTACH_ID}"

# small wait before starting the scan to let everything catch up.
sleep 10

# ----------------------------------------------------------------------
# step 4 - initiate an ondemand scan for the attachment
# ----------------------------------------------------------------------
SCAN_JSON=$(ibmcloud scc attachment scan --attachment-id "$ATTACH_ID" --output json)
if [[ -z "$SCAN_JSON" || $? != 0 ]]; then
    echo "Unable to query the ondemand scan for attachment id $ATTACH_ID. Scan may not have been initiated successfully. Exiting."
    exit 1
fi

SCAN_ID=$(echo "${SCAN_JSON}" | jq -r '.id')
if [[ -z "${SCAN_ID}" || "${SCAN_ID}" == "null" ]]; then
    echo "Unable to determine the ondemand scan id.  Exiting."
    exit 1
fi

echo "Scan initiated.  Scan id is ${SCAN_ID}"
# wait so that scan status may be updated in the backend.  
sleep 30

# ----------------------------------------------------------------------
# step 5 - wait for the scan to complete by querying its status
# ----------------------------------------------------------------------

elapsedSeconds=0
scanDone=0
retries=0
while [ ${scanDone} -eq 0 ]
do
    # query the attachment and look at the last scan information
    ATTACH_DETAIL_JSON=$(ibmcloud scc attachment get --attachment-id "$ATTACH_ID" --profile-id "$PROFILE_ID" --output json)
    if [[ -z "$ATTACH_DETAIL_JSON" || $? != 0 ]]; then
        echo "Unable to get status of scan for attachment.  ibmcloud return code was $? ... retrying."
        sleep ${SCAN_QUERY_WAIT} 
        ((retries=retries + 1))

        if [[ ${retries} -gt ${MAX_SCAN_QUERY_RETRIES} ]]; then
            echo "Maximum retries ${MAX_SCAN_QUERY_RETRIES} exceeded attempting to get scan status.  Exiting."
            exit 1
        fi
    else
        # 
        LAST_SCAN_ID=$(echo "${ATTACH_DETAIL_JSON}" | jq -r '.last_scan.id')
        if [[ "${LAST_SCAN_ID}" != "null" && "${LAST_SCAN_ID}" == "${SCAN_ID}" ]]; then
            SCAN_STATUS=$(echo "${ATTACH_DETAIL_JSON}" | jq -r '.last_scan.status')
            if [[ "${SCAN_STATUS}" == "completed" ]]; then
                scanDone=1
                echo "Scan completed"
            else
                echo "scan status: ${SCAN_STATUS} - Elapsed seconds: ${elapsedSeconds}"
                # scan is not yet done.  sleep before querying status again.
                sleep ${SCAN_QUERY_WAIT}
                ((elapsedSeconds=elapsedSeconds + SCAN_QUERY_WAIT))

                # see if scan has been running too long
                if [[ ${elapsedSeconds} -gt ${MAX_SCAN_SECONDS} ]]; then
                    echo "Timeout waiting for scan to complete.  Scan time has exceeded the max of ${MAX_SCAN_SECONDS} ."
                    exit 1
                fi

                # scans can take a while.  refresh the user login session every 5 minutes
                if [ $((elapsedSeconds % 300)) = 0 ]; then
                    echo "Refreshing iam token"
                    ibmcloud catalog utility netrc
                fi
            fi
        fi        
    fi
done

echo "Scan ID ${SCAN_ID} is complete!"

# ----------------------------------------------------------------------
# step 6 - apply the scan results to the version of the offering 
# ----------------------------------------------------------------------

# login as the owner of the catalog so that we can update it.
echo "Logging CLI into catalog account.."
ibmcloud login --apikey "${CATALOG_API_KEY}" --no-region

scc_apply_cmd="ibmcloud catalog offering version scc-apply --scan ${SCAN_ID} --version-locator ${VERSION_LOCATOR} --timeout 7200 --service-instance ${SCC_INSTANCE_ID} --instance-region ${SCC_REGION}"
if [ "${SCC_API_KEY}" != "${CATALOG_API_KEY}" ]; then
    scc_apply_cmd+=" --target-api-key ${SCC_API_KEY}"
fi

# apply the scan to the version, retry up to 3 times
attempts=0
retries=3
while [[ ${attempts} -le ${retries} ]]; do
    sleep 10
    attempts=$((attempts+1))
    echo "Appling scan results to offering version in catalog."
    if ${scc_apply_cmd}; then
        break
    else
        echo "Applying scan to the offering version failed."
        if [[ ${attempts} -lt ${retries} ]]; then
            echo "Retrying.."
            echo
        else
            echo "Maximum attempts reached, giving up!"
            exit 1
        fi
    fi
done

# ----------------------------------------------------------------------
# step 7 - clean up by deleting the SCC attachment
# ----------------------------------------------------------------------

# log back into the SCC account to get a new access token
echo "Logging CLI into SCC owning account."
ibmcloud login --apikey "${SCC_API_KEY}" --no-region

# delete the attachment
scc_delete_attach_cmd=$(ibmcloud scc attachment delete --attachment-id "$ATTACH_ID" --profile-id "$PROFILE_ID")
if [[ ${scc_delete_attach_cmd} != 0 ]]; then
    echo "An error occurred while deleting the SCC attachment with id $ATTACH_ID . Manual clean may be necessary."
fi

echo "Done with SCC scan"
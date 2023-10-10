#! /bin/bash

# hard fail on errors
set -eo pipefail

####################################################################################
# SCRIPT LOGIC FLOW
# 1. Log CLI into catalog account
# 2. Query ID of Profile by using supplied Name and Version
# 3. Retrieve the "default_parameters" array from Profile detail
# 3a. Update default allowed images param from CLI
# 4. Create a new attachment for profile (with disabled scan schedule)
# 5. Initiate on-demand scan for attachment
# 6. Query scan status in attachment detail, loop until "complete" or timeout expires
# 7. Update catalog with completed SCAN_ID
# 8. Delete attachment created in step 4
####################################################################################

MAX_SCAN_SECONDS=5400  # 90 mins
SCAN_QUERY_WAIT=30     # seconds
PRG=$(basename -- "${0}")

########################################
# BEGIN SCRIPT SETUP
########################################
USAGE="
usage:	${PRG}
        [--help]

        Required environment variables:
        CATALOG_API_KEY - api key from the account where the catalog exists
        SCC_API_KEY - api key from the account where the SCC instance + deployed resources exist

        Required arguments:
        --profile_name=<profile_name>
        --profile_version=<profile version>
        --account_id=<account_id>
        --instance_id=<instance_id>
        --scc_region=<region>
        --version_locator=<version_locator>
"


# Verify required environment variables are set
all_env_vars_exist=true
env_var_array=( CATALOG_API_KEY SCC_API_KEY )
set +u
for var in "${env_var_array[@]}"; do
  [ -z "${!var}" ] && echo "$var not defined." && all_env_vars_exist=false
done
set -u
if [ ${all_env_vars_exist} == false ]; then
  echo "One or more required environment variables are not defined. Exiting."
  exit 1
fi

PROFILE_NAME=""
PROFILE_VERSION=""
ACCOUNT_ID=""
INSTANCE_ID=""
SCC_REGION=""
VERSION_LOCATOR=""

# Loop through all args
for arg in "$@"; do
    set +e
    found_match=false

    if echo "${arg}" | grep -q -e --profile_name=; then
        PROFILE_NAME=$(echo "${arg}" | awk -F= '{ print $2 }')
        found_match=true
    fi

    if echo "${arg}" | grep -q -e --profile_version=; then
        PROFILE_VERSION=$(echo "${arg}" | awk -F= '{ print $2 }')
        found_match=true
    fi

    if echo "${arg}" | grep -q -e --account_id=; then
        ACCOUNT_ID=$(echo "${arg}" | awk -F= '{ print $2 }')
        found_match=true
    fi

    if echo "${arg}" | grep -q -e --instance_id=; then
        INSTANCE_ID=$(echo "${arg}" | awk -F= '{ print $2 }')
        found_match=true
    fi

    if echo "${arg}" | grep -q -e --scc_region=; then
        SCC_REGION=$(echo "${arg}" | awk -F= '{ print $2 }')
        found_match=true
    fi

    if echo "${arg}" | grep -q -e --version_locator=; then
        VERSION_LOCATOR=$(echo "${arg}" | awk -F= '{ print $2 }')
        found_match=true
    fi

    if [ ${found_match} = false ]; then
        if [ "${arg}" != --help ]; then
            echo "Unknown command line argument:  ${arg}"
        fi
        echo "${USAGE}"
        exit 1
    fi

    set -e
done

# Verify values have been passed for required args
all_args_exist=true
var_array=( PROFILE_NAME PROFILE_VERSION ACCOUNT_ID INSTANCE_ID SCC_REGION VERSION_LOCATOR )
set +u
for var in "${var_array[@]}"; do
    [ -z "${!var}" ] && echo "$var not set." && all_args_exist=false
done
set -u

if [ ${all_args_exist} == false ]; then
    echo "Missing one ore more required arguments. See usage below:"
    echo "${USAGE}"
    exit 1
fi
########################################
# END SCRIPT SETUP
########################################

# SCC API endpoint setup
SCC_API_BASE_URL="https://$SCC_REGION.compliance.cloud.ibm.com/instances/$INSTANCE_ID/v3"

# use api key to get an access token
IAM_RESPONSE=$(curl -s --request POST \
'https://iam.cloud.ibm.com/identity/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Accept: application/json' \
--data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' --data-urlencode 'apikey='"${SCC_API_KEY}") # pragma: allowlist secret

ERROR_MESSAGE=$(echo "${IAM_RESPONSE}" | jq 'has("errorMessage")')
if [[ "${ERROR_MESSAGE}" != false ]]; then
    echo "${IAM_RESPONSE}" | jq '.errorMessage'
    echo "Could not obtain an access token"
    exit 1
fi

ACCESS_TOKEN=$(echo "${IAM_RESPONSE}" | jq -r '.access_token')

####################################################################################
# STEP 1: Log CLI into catalog account
####################################################################################
echo "Logging CLI into catalog account.."
ibmcloud login --apikey "${CATALOG_API_KEY}" --no-region
ibmcloud target -r us-south  # need to target a region to list images later

####################################################################################
# STEP 2: determine the profile's id
####################################################################################
PROFILE_ID=""
PROFILE_JSON=$(curl --silent --location --request GET \
"${SCC_API_BASE_URL}/profiles" \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer '"${ACCESS_TOKEN}")

PROFILE_ID=$(echo "${PROFILE_JSON}" | jq -r --arg PROFILE_NAME "${PROFILE_NAME}" --arg PROFILE_VERSION "${PROFILE_VERSION}" '.profiles[] | select(.profile_name == $PROFILE_NAME and .profile_version == $PROFILE_VERSION) | {id}' | jq -r .id)
if [[ -z "${PROFILE_ID}" ]]; then
    echo "Could not determine profile id for profile named: ${PROFILE_NAME}"
    exit 1
fi

echo "Profile id is ${PROFILE_ID} for profile named ${PROFILE_NAME}"

####################################################################################
# STEP 3: get default parameters for profile, needed for attachment
####################################################################################
PROFILE_DETAIL_JSON=$(curl --silent --location --request GET \
"${SCC_API_BASE_URL}/profiles/${PROFILE_ID}" \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer '"${ACCESS_TOKEN}")

# get default params array from profile detail and rename 'parameter_default_value' field to 'parameter_value'
DEFAULT_PARAMS_JSON=$(echo "${PROFILE_DETAIL_JSON}" | jq -r '[.default_parameters[] | .["parameter_value"] = .parameter_default_value | del(.parameter_default_value)]')
if [[ -z "${DEFAULT_PARAMS_JSON}" ]]; then
    echo "Could not determine profile default parameters for profile named: ${PROFILE_NAME}"
    exit 1
fi

####################################################################################
# STEP 3a: get default parameters for profile, needed for attachment
####################################################################################
ACTIVE_IMAGE_LIST=$(ibmcloud is images --output json | jq -c '[.[] | select(.status == "available" and .operating_system.dedicated_host_only == false and .operating_system.architecture == "amd64") | .name]' | sed "s/\"/'/g")
if [[ -n "${ACTIVE_IMAGE_LIST}" ]]; then
    echo "Using ACTIVE image list"
    NEW_PARAMS_JSON=$(echo "${DEFAULT_PARAMS_JSON}" | jq --arg IMAGES "${ACTIVE_IMAGE_LIST}" '(.[] | select(.parameter_name == "defined_images") | .parameter_value) = $IMAGES')
else
    echo "Using default params"
    NEW_PARAMS_JSON="${DEFAULT_PARAMS_JSON}"
fi

####################################################################################
# STEP 4: create a new attachment for the scan
####################################################################################
ATTACH_ID=""
ATTACHMENT_NAME="catalog-pipeline-$(date +%Y%m%d%H%M%S)"
ATTACH_RESULT_JSON=$(curl --silent --request POST \
"${SCC_API_BASE_URL}/profiles/${PROFILE_ID}/attachments" \
--header 'Authorization: Bearer '"${ACCESS_TOKEN}" \
--header 'Content-Type: application/json' \
--data-raw '{"account_id": "'"${ACCOUNT_ID}"'", "attachments": [{"included_scope": {"scope_id": "'"${ACCOUNT_ID}"'", "scope_type": "account"}, "exclusions": [], "status": "disabled", "attachment_parameters": '"${NEW_PARAMS_JSON}"', "name": "'"${ATTACHMENT_NAME}"'"}]}')


if [[ -z "${ATTACH_RESULT_JSON}" ]]; then
    echo "Failed to create new attachment for profile named: ${PROFILE_NAME}"
    exit 1
fi

ATTACH_ID=$(echo "${ATTACH_RESULT_JSON}" | jq -r '.attachments[0].id')
if [[ -z "${ATTACH_ID}" || "${ATTACH_ID}" == "null" ]]; then
    echo "Failed to retrieve new ATTACHMENT_ID for profile named: ${PROFILE_NAME}"
    echo "DEBUG: ATTACH_RESULT_JSON:"
    echo "${ATTACH_RESULT_JSON} | jq"
    exit 1
fi

echo "Attachment created: ${ATTACH_ID}"

sleep 10 # wait before starting scan

####################################################################################
# STEP 5: initiate an existing on demand scc scan for attachment
####################################################################################
SCAN_RESULT=$(curl --silent --request POST \
"${SCC_API_BASE_URL}/scans" \
--header 'Authorization: Bearer '"${ACCESS_TOKEN}" \
--header 'Content-Type: application/json' \
--data-raw '{ "attachment_id": "'"${ATTACH_ID}"'"}')

SCAN_ID=$(echo "${SCAN_RESULT}" | jq -r '.id')
if [[ -z "${SCAN_ID}" || "${SCAN_ID}" == "null" ]]; then
    echo "error getting Scan ID.   result=${SCAN_RESULT}"
    echo
    echo "Could not initiate OnDemand SCC scan."
    exit 1
fi

echo
echo "Scan initiated: ${SCAN_ID}"

# need to either wait an amount of time for the scan to start.  if we query the status too soon the last
# completed status will be returned.
sleep 30

####################################################################################
# STEP 6: query attachment detail until scan status is complete
####################################################################################
elapsedSeconds=0
scanDone=0
while [ ${scanDone} -eq 0 ]
do
    # look for last scan in attachment detail
    ATTACH_DETAIL_JSON=$(curl --silent --location --request GET \
    "${SCC_API_BASE_URL}/profiles/${PROFILE_ID}/attachments/${ATTACH_ID}" \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '"${ACCESS_TOKEN}")

    # save the return code from curl command
    CURL_RC=$?

    # check for errors making the call
    if [[ -z "${ATTACH_DETAIL_JSON}" || ${CURL_RC} != 0 ]]
    then
        echo "Error getting status of the attachment."
        echo "Attachment detail is ${ATTACH_DETAIL_JSON}"
        echo "curl return code is ${CURL_RC}"
        echo
        exit 1
    fi

    # exmaine the attach detail response.  look for the key "last_scan" in the response, and make sure that scan_id matches the one created above
    LAST_SCAN_ID=$(echo "${ATTACH_DETAIL_JSON}" | jq -r '.last_scan.id')
    if [[ "${LAST_SCAN_ID}" != "null" && "${LAST_SCAN_ID}" == "${SCAN_ID}" ]]
    then
        SCAN_STATUS=$(echo "${ATTACH_DETAIL_JSON}" | jq -r '.last_scan.status')
        if [[ "${SCAN_STATUS}" == "completed" ]]
        then
            scanDone=1
            echo "Scan completed"
        else
            echo "scan status: ${SCAN_STATUS} - Elapsed seconds: ${elapsedSeconds}"
            # scan is not yet done.  sleep before querying status again.
            sleep ${SCAN_QUERY_WAIT}
            ((elapsedSeconds=elapsedSeconds + SCAN_QUERY_WAIT))

            # see if scan has been running too long
            if [[ ${elapsedSeconds} -gt ${MAX_SCAN_SECONDS} ]]
            then
                echo "Timeout waiting for scan to complete.  Scan time has exceeded the max of ${MAX_SCAN_SECONDS} ."
                exit 1
            fi

            # refresh the token every 5 minutes = 300 seconds
            if [ $((elapsedSeconds % 300)) = 0 ]; then
                echo "Refreshing iam token"
                # use api key to get an access token
                IAM_RESPONSE=$(curl -s --request POST \
                'https://iam.cloud.ibm.com/identity/token' \
                --header 'Content-Type: application/x-www-form-urlencoded' \
                --header 'Accept: application/json' \
                --data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' --data-urlencode 'apikey='"${SCC_API_KEY}") # pragma: allowlist secret

                ERROR_MESSAGE=$(echo "${IAM_RESPONSE}" | jq 'has("errorMessage")')
                if [[ "${ERROR_MESSAGE}" != false ]]; then
                    echo "${IAM_RESPONSE}" | jq '.errorMessage'
                    echo "Could not obtain an access token"
                    exit 1
                fi
                ACCESS_TOKEN=$(echo "${IAM_RESPONSE}" | jq -r '.access_token')
            fi
        fi
    else
        echo "Unexpected response from the SCC service while getting status of scan."
        echo "response is ${ATTACH_DETAIL_JSON}"
        echo
        exit 1
    fi
done

echo "Scan ID ${SCAN_ID} is complete!"

# need to make sure the scan has recorded it status fully within the SCC database.  Temporarily wait 30 sec to be sure.
echo "Waiting for 30 secs to make sure the scan has recorded its status fully within the SCC database.."
sleep 30

####################################################################################
# STEP 7: apply the scan results to a version of an offering in the catalog
####################################################################################
set +u
if [[ -z "${SKIP_CATALOG_UPDATE}" ]]; then
    attempts=0
    retries=3

    # see https://github.ibm.com/GoldenEye/issues/issues/5673#issuecomment-62087361
    export BLUEMIX_CM_TIMEOUT=7200

    scc_apply_cmd="ibmcloud catalog offering version scc-apply --scan ${SCAN_ID} --version-locator ${VERSION_LOCATOR} --timeout ${BLUEMIX_CM_TIMEOUT}"
    if [ "${SCC_API_KEY}" != "${CATALOG_API_KEY}" ]; then
        scc_apply_cmd+=" --target-api-key ${SCC_API_KEY}"
    fi

    while [[ ${attempts} -le ${retries} ]]; do
        sleep 10
        attempts=$((attempts+1))
        echo "Applying SCC scan, attempt ${attempts}"
        if ${scc_apply_cmd}; then
            break
        else
            echo "Applying scan to the version failed."
            if [[ ${attempts} -lt ${retries} ]]; then
                echo "Retrying.."
                echo
            else
                echo "Maximum attempts reached, giving up!"
                exit 1
            fi
        fi
    done
    unset BLUEMIX_CM_TIMEOUT
else
    echo "Skipping Catalog Update (OS env variable SKIP_CATALOG_UPDATE was set)"
fi
set -u

# perform one more token refresh in case catalog update took a while
IAM_RESPONSE=$(curl -s --request POST \
'https://iam.cloud.ibm.com/identity/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Accept: application/json' \
--data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' --data-urlencode 'apikey='"${SCC_API_KEY}") # pragma: allowlist secret

ERROR_MESSAGE=$(echo "${IAM_RESPONSE}" | jq 'has("errorMessage")')
if [[ "${ERROR_MESSAGE}" != false ]]; then
    echo "${IAM_RESPONSE}" | jq '.errorMessage'
    echo "Could not obtain an access token"
    exit 1
fi
ACCESS_TOKEN=$(echo "${IAM_RESPONSE}" | jq -r '.access_token')

####################################################################################
# STEP 8: Delete the attachment
####################################################################################
echo "Deleting attachment ${ATTACH_ID}"
ATTACH_DELETE_JSON=$(curl --silent --request DELETE \
"${SCC_API_BASE_URL}/profiles/${PROFILE_ID}/attachments/${ATTACH_ID}" \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '"${ACCESS_TOKEN}")
CURL_RC=$?
ATTACH_DELETE_HAS_ERRORS=$(echo "${ATTACH_DELETE_JSON}" | jq 'has("errors")')
if [[ "${CURL_RC}" != 0 || "${ATTACH_DELETE_HAS_ERRORS}" == true ]]; then
    echo "Error deleting attachment"
    echo "Attach delete response: ${ATTACH_DELETE_JSON}"
    exit 1
fi

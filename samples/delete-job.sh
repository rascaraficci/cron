#!/bin/bash

USAGE="$0 -d <dojot-url> -u <dojot-user> -p <dojot-password> [-j <job-id>]"

while getopts "d:u:p:j:" options; do
  case $options in
    d ) DOJOT_URL=$OPTARG;;
    u ) DOJOT_USERNAME=$OPTARG;;
    p ) DOJOT_PASSWD=$OPTARG;;
    j ) CRON_JOB_ID=$OPTARG;;
    \? ) echo ${USAGE}
         exit 1;;
    * ) echo ${USAGE}
          exit 1;;
  esac
done

if [ -z ${DOJOT_URL} ] || [ -z ${DOJOT_USERNAME} ] ||
   [ -z ${DOJOT_PASSWD} ]
then
    echo ${USAGE}
    exit 1
fi

# JWT Token
echo 'Getting jwt token ...'
JWT=$(curl --silent -X POST ${DOJOT_URL}/auth \
-H "Content-Type:application/json" \
-d "{\"username\": \"${DOJOT_USERNAME}\", \"passwd\" : \"${DOJOT_PASSWD}\"}" | jq '.jwt' | tr -d '"')
echo "... Got jwt token ${JWT}."


# Delete cron job(s)
if [ -z ${CRON_JOB_ID} ]
then
  echo "Deleting all cron jobs ..."
else
    echo "Deleting cron job ${CRON_JOB_ID} ..."
fi

RESPONSE=$(curl -w "\n%{http_code}" --silent -X DELETE ${DOJOT_URL}/cron/v1/jobs/${CRON_JOB_ID} \
-H "Authorization: Bearer ${JWT}")
RESPONSE=(${RESPONSE[@]}) # convert to array
HTTP_STATUS=${RESPONSE[-1]} # get last element (last line)
BODY=(${RESPONSE[@]::${#RESPONSE[@]}-1}) # get all elements except last

if [ "${HTTP_STATUS}" == "204" ]
then
  echo "... Succeeded to delete job(s)."
else
  echo "... Failed to delete job(s)."
  echo "${BODY[*]}"
fi

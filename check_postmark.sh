#!/bin/bash

# DMARK Postmark Check for checkmk, Nagios/Icinga
#
# Christian Wirtz, 11/2019, doc@snowheaven.de
#
#######################################################################
#  Copyright (C) 2019 Christian Wirtz <doc@snowheaven.de>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#######################################################################
#
# Usage
# ./check_postmark.sh <API-Token> <Request>
#
# Requests
# - verify  -> Verify if your DMARC DNS record exists.
# - record  -> Get a record’s information.
# - snippet -> Get generated DMARC DNS record name and value.
# - reports -> List all received DMARC reports for a given domain with the ability to filter results by a single date or date range.
#
# Help/Links
# https://de.wikipedia.org/wiki/DMARC
# https://dmarc.postmarkapp.com
# https://dmarc.postmarkapp.com/api/
#

# Minimum of two paramaters
if [[ "$#" -ne 2 ]]; then
    echo -e "Usage: check_postmark.sh <API-Token> <Request> -> Requests: {verify,record,snippet,reports}"
    exit 3
fi

TODAY="$(date '+%Y-%m-%d')"
TO="$(date --date='7 days ago' '+%Y-%m-%d')"

if [[ "verify" == $2 ]]; then
    RESULT=`curl --silent "https://dmarc.postmarkapp.com/records/my/verify" \
              -X POST \
              -H "Accept: application/json" \
              -H "X-Api-Token: $1"`
elif [[ "record" == $2 ]]; then
    RESULT=`curl --silent "https://dmarc.postmarkapp.com/records/my" \
              -X GET \
              -H "Accept: application/json" \
              -H "X-Api-Token: $1"`
elif [[ "snippet" == $2 ]]; then
    RESULT=`curl --silent "https://dmarc.postmarkapp.com/records/my/dns" \
              -X GET \
              -H "Accept: application/json" \
              -H "X-Api-Token: $1"`
elif [[ "reports" == $2 ]]; then
    RESULT=`curl --silent "https://dmarc.postmarkapp.com/records/my/reports?from_date=${TODAY}&to_date=${TO}&reverse" \
              -X GET \
              -H "Accept: application/json" \
              -H "X-Api-Token: $1"`
fi


#echo -e "${RESULT}"


MESSAGE="an error occoured"
EXIT_CODE=3

if [[ "verify" == $2 ]]; then
    VERIFY=`echo ${RESULT} | jq .verified`
    if [[ "false" == ${VERIFY} ]]; then
        MESSAGE="A valid DNS record does not exist"
        EXIT_CODE=1
    elif [[ "true" == ${VERIFY} ]]; then
        MESSAGE="A valid DNS record exists"
        EXIT_CODE=0
    else
        MESSAGE="no result"
        EXIT_CODE=3
    fi
elif [[ "record" == $2 ]]; then
    DOMAIN=`echo ${RESULT} | jq .domain`
    TOKEN=`echo ${RESULT} | jq .public_token`
    CREATED=`echo ${RESULT} | jq .created_at`
    URI=`echo ${RESULT} | jq .reporting_uri`
    EMAIL=`echo ${RESULT} | jq .email`

    MESSAGE="Domain: ${DOMAIN}, Public Token: ${TOKEN}, Created at: ${CREATED}, Reporting URI: ${URI}, EMail: ${EMAIL}"
    EXIT_CODE=0
elif [[ "snippet" == $2 ]]; then
    VALUE=`echo ${RESULT} | jq .value`
    NAME=`echo ${RESULT} | jq .name`

    MESSAGE="Hostname: ${NAME}, Value: ${VALUE}"
    EXIT_CODE=0
elif [[ "reports" == $2 ]]; then
    NEXT=`echo ${RESULT} | jq .meta.next`
    NEXTURL=`echo ${RESULT} | jq .meta.next_url`
    TOTAL=`echo ${RESULT} | jq .meta.total`

    MESSAGE="Total: ${TOTAL}, Next: ${NEXT}, Next URL: <a href='https://dmarc.postmarkapp.com/${NEXTURL}' target='_blank'>Report ${NEXT}</a>"
    EXIT_CODE=0
fi

echo -e "${MESSAGE}"

exit ${EXIT_CODE}

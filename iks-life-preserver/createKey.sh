#!/bin/bash

ibmcloud login -a cloud.ibm.com --apikey $1 -c $2 -r us-south --quiet > /dev/null
ibmcloud iam service-api-key-create life-preserver life-preserver-id-$3 --output json | jq ". | {id: .id, name: .name, acct: .account_id, apikey: .apikey}"
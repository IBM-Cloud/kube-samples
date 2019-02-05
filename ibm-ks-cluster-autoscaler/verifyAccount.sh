#!/bin/sh
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ "$#" -ne 1 ];
then
  echo "${RED}Please provide cluster name as an input${NC}"
  echo "Like  'sh verifyAccount.sh mycluster' "
  exit
fi

TOKEN=`ibmcloud iam oauth-tokens | awk '{print $3" "$4}'`
AUTH="'Authorization:$TOKEN'"
CLUSTER_NAME=$1

CLUSTER_ID=`ibmcloud ks clusters | grep $CLUSTER_NAME | awk '{print $2}'`
if [ -z "$CLUSTER_ID" ];
then
  echo "${RED}Looks cluster name not found, please check manually by using 'ibmcloud ks clusters'${NC}"
  exit
fi

WORKER_POOL_ID=`ibmcloud ks worker-pools --cluster $CLUSTER_NAME | grep default | awk '{print $2}'`
if [ -z "$WORKER_POOL_ID" ];
then
  echo "${RED}Looks default worker pool not found, please check manually by using 'ibmcloud ks worker-pools --cluster cluster-name'${NC}"
  exit
fi
REGION=`ibmcloud ks api | grep "Region:" | awk '{print $2}'`

eval curl -X GET https://${REGION}.containers.bluemix.net/v1/clusters/$CLUSTER_ID/workerpools/$WORKER_POOL_ID/instancegroups -H $AUTH > temp 2>&1

cat temp | grep $WORKER_POOL_ID > /dev/null 2>&1

if [ $? == 0 ];
then
  echo "${GREEN}Your account is whitelisted and you can use IBM Cluster Autoscaler${NC}"
else
  echo "${RED}Your account is not whitelisted you can't use IBM Cluster Autoscaler${NC}"
fi
rm -rf temp

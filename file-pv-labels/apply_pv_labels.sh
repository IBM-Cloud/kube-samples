#!/bin/sh

#/******************************************************************************
 # * Licensed Materials - Property of IBM
 # * IBM Cloud Kubernetes Service, 5737-D42
 # * (C) Copyright IBM Corp. 2018 All Rights Reserved.
 # * US Government Users Restricted Rights - Use, duplication or
 # * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 # ****************************************************************************/

# Use this script when you update your cluster from single-zone to multizone and have existing persistent volumes (PVs).
# Before you begin:
# (1) ibmcloud ks login
# (2) Set the cluster context. Run 'ibmcloud ks cluster-config <mycluster>'. Then copy and paste the KUBECONFIG environment variable output.

if [ "$1" == "-h" ]
then
	echo "Usage: ./apply_pv_labels.sh <CLUSTER NAME>"
	exit 0
fi

cluster_name=$1
ibmcloud ks cluster-get $cluster_name
if [ $? -ne 0 ]
then
	echo "ERROR: The cluster ${cluster_name} does not exist"
	exit 1
fi

region=$(ibmcloud ks region | cut -d ':' -f 2 | tr -d "[:blank:]")
echo $region

if [ -z "$KUBECONFIG" ] || [ "$KUBECONFIG" == " " ]
then
	echo "KUBECONFIG environment variable is not set"
	exit 1
fi

kubeconfig=$(echo $KUBECONFIG | awk -F/ '{print $NF}')
echo $kubeconfig

cluster_file_name=$cluster_name".yml"
echo $cluster_file_name

if [[ $kubeconfig != *$cluster_file_name ]]
then
	echo "Incorrect KUBECONFIG set for the cluster ${cluster_name}"
	exit 1
fi

dc=$(kubectl -n kube-system exec $(kubectl -n kube-system get pods | grep ibm-file-plugin | awk '{print $1}') cat /etc/storage_ibmc/slclient.toml | grep softlayer_datacenter | cut -d '=' -f 2 | tr -d "[:blank:]" | tr -d '"')
echo $dc\\n

read -p "The persistent volumes which do not have region and zone labels will be updated with REGION=$region and ZONE=$dc. Are you sure to continue (y/n)?" REPLY
if [ "$REPLY" = "y" ]
then
	kubectl label pv --all failure-domain.beta.kubernetes.io/region=$(echo $region) failure-domain.beta.kubernetes.io/zone=$(echo $dc) --overwrite=false
	echo "\nSuccessfully applied labels to persistent volumes which did not have region and zone labels."
else
  echo "\nDid not apply any labels to persistent volumes."
fi

# Virtual Private Endpoint Gateway Examples

This folder contains Virtual Private Endpoint (VPE) Gateway related scripts and information.

## create-iam-vpe-gateway.sh

A script that can be used to create and then remove a VPE Gateway for IAM similar to what will be created for IBM Cloud VPC Kubernetes and Openshift managed clusters.  See the [IBM Cloud IAM VPE Gateway documentation](https://cloud.ibm.com/docs/containers?topic=containers-vpc-iam-vpe-gateway) for more information.

## Fixes to this script

1. In the initial version of this script, the IAM VPE Gateway that was created was named "kube-iam-VPCID", which was incorrect.  It has since been corrected to use the name "iks-iam-VPCID".  If you created the IAM VPE Gateway with the script that used the "kube-iam-VPCID" name, then you should just rename it to iks-iam-VPDID, there is no need to re-run the script

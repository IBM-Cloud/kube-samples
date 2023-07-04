#!/bin/bash

# IC_API_KEY environment variable should be set
# see: https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-provider-reference

# Run Terraform to provision two IKS clusters
terraform init
terraform apply

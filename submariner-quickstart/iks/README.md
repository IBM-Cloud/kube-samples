# Submariner Quickstart on IBM Cloud

This quick start guide demonstrates how to set up Submariner on two newly created IBM Cloud Kubernetes (IKS) clusters.

## Prerequisites

- [IBM Cloud account](https://cloud.ibm.com/docs/account?topic=account-account-getting-started)
- [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## Run

```shell
./10_create_clusters.sh
./20_deploy_submariner.sh
./30_verify.sh
```

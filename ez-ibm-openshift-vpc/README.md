# EZ-IBM-OPENSHIFT-VPC

Creates a single-zone VPC Red Hat Openshift on IBM Cloud cluster in US East. To be used with Terraform or IBM Cloud Schematics. Allows for a quick build and teardown of an Openshift cluster and VPC environment.

These Terraform resources will create:
- VPC
- Subnet
- Public gateway
- COS bucket
- Single-zone two-node OpenShift cluster

To create using Schematics:

1. Log in to IBM Cloud
2. Select IBM Cloud Schematics
3. Create a work space.
4. For `GitHub, GitLab or Bitbucket repository URL`, input this URL: `https://github.com/IBM-Cloud/kube-samples/tree/master/ez-ibm-openshift-vpc`
5. Uncheck `Use Full Repository` and select `Next`.
6. Complete `Workplace Details` as desired, select `Next`, then select `Create` to populate your new Schematics workspace.
7. Once the workspace is completed, select `Apply plan` to create your VPC and OpenShift cluster.
8. To delete the resources, select `Actions` > `Destroy Resources` 

To change this to a multizone cluster, update the variable `number_of_zones` to `2` or `3`. This will create a VPC and cluster that spans 2-3 zones, respectively.

source: [IBM Cloud Terraform provider](https://github.com/IBM-Cloud/terraform-provider-ibm/tree/master/examples/ibm-cluster/roks-on-vpc-gen2)
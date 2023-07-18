# This example template is for informational purposes only and is not intended for production use

terraform {
  required_version = ">=0.13"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.55.0"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
}

### Create the Secrets Manager instance
resource "ibm_resource_instance" "sm_instance" {
  name     = var.sm_instance_name
  service  = "secrets-manager"
  plan     = var.sm_instance_plan
  location = var.sm_instance_region
  timeouts {
    create = "60m"
    delete = "2h"
  }

}

### Create a secret group in the Secrets Manager instance
resource "ibm_sm_secret_group" "sm_secret_group" {
  instance_id = ibm_resource_instance.sm_instance.guid
  region      = ibm_resource_instance.sm_instance.location
  name        = var.sm_secret_group_name
  description = var.sm_secret_group_description
}

### Create service-to-service authorizations
resource "ibm_iam_authorization_policy" "sm_auth" {
  source_service_name = "containers-kubernetes"
  target_service_name = "secrets-manager"
  roles               = ["Manager"]
}

### Register the Secrets Manager instance to the cluster
### See documentation https://cloud.ibm.com/docs/containers?topic=containers-secrets-mgr#secrets-mgr_setup_create
resource "ibm_container_ingress_instance" "instance" {
  cluster         = var.cluster_name_or_id
  secret_group_id = ibm_sm_secret_group.sm_secret_group.secret_group_id
  instance_crn    = ibm_resource_instance.sm_instance.id
  is_default      = true
}

### See API https://cloud.ibm.com/apidocs/secrets-manager/secrets-manager-v2#create-secret

### Create an arbitrary secret in Secrets Manager
resource "ibm_sm_arbitrary_secret" "sm_arbitrary_secret" {
  instance_id     = ibm_resource_instance.sm_instance.guid
  region          = ibm_resource_instance.sm_instance.location
  endpoint_type   = var.sm_endpoint_type
  name            = var.sm_arbitrary_secret_name
  description     = var.sm_arbitrary_secret_description
  expiration_date = var.sm_arbitrary_secret_expiration_date
  labels          = var.sm_arbitrary_secret_labels
  secret_group_id = ibm_sm_secret_group.sm_secret_group.secret_group_id
  payload         = var.sm_arbitrary_secret_payload
}

### Create an username password secret in Secrets Manager
resource "ibm_sm_username_password_secret" "sm_username_password_secret" {
  instance_id     = ibm_resource_instance.sm_instance.guid
  region          = ibm_resource_instance.sm_instance.location
  endpoint_type   = var.sm_endpoint_type
  name            = var.sm_username_password_secret_name
  description     = var.sm_username_password_secret_description
  expiration_date = var.sm_username_password_secret_expiration_date
  labels          = var.sm_username_password_secret_labels
  secret_group_id = ibm_sm_secret_group.sm_secret_group.secret_group_id
  rotation {
    auto_rotate = true
    interval    = 1
    unit        = "day"
  }

  username = var.sm_username_password_secret_username
  password = var.sm_username_password_secret_password
}

### Create an Opaque secret in the cluster with the CRNs of the secrets created above
### Sec documentation https://cloud.ibm.com/docs/containers?topic=containers-secrets
resource "ibm_container_ingress_secret_opaque" "secret_opaque" {
  cluster          = var.cluster_name_or_id
  secret_name      = var.opaque_secret_name
  secret_namespace = var.opaque_secret_namespace
  persistence      = true
  fields {
    crn = ibm_sm_arbitrary_secret.sm_arbitrary_secret.crn
  }
  fields {
    crn = ibm_sm_username_password_secret.sm_username_password_secret.crn
  }
}

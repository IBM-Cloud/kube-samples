# IBM provider variables
# uncomment if using local terraform
# variable "ibmcloud_api_key" {}

# Global variables
variable "name" {
  type        = string
  default     = "ez-openshift-vpc"
  description = "The name used for creating the VPC, cluster, and other resources. The name will be appended by a random 4 digit string."
}

variable "region" {
  type        = string
  default     = "us-east"
  description = "The region to deploy the resources to."
}

variable "resource_group" {
  type        = string
  default     = "default"
  description = "The resource group to deploy the resources to."
}

variable "number_of_zones" {
  type        = number
  default     = 1
  description = "The number of zones to create for the VPC and cluster. Valid inputs are 1, 2, or 3."
  validation {
    condition     = var.number_of_zones >= 1 && var.number_of_zones <= 3
    error_message = "Valid inputs are 1, 2, or 3."
  }
}

# OpenShift variables
variable "worker_flavor" {
  type        = string
  default     = "bx2.4x16"
  description = "The VPC virtual machine types to use for the cluster worker nodes."
}

variable "workers_per_zone" {
  type        = string
  default     = "2"
  description = "The number of workers to have in each zone of the cluster. Suggested minimum is 2."
}

variable "public_service_endpoint_disabled" {
  type        = bool
  default     = false
  description = "Whether or not to disable the public endpoint for the cluster."
}

variable "kube_version" {
  type        = string
  default     = null
  description = "The OpenShift version. This terraform script chooses dynamically from the list of supported versions."
}

# Cloud Object Storage (COS) variables
variable "service_offering" {
  type        = string
  default     = "cloud-object-storage"
  description = "The IBM Cloud service to provision."
}

variable "plan" {
  type        = string
  default     = "standard"
  description = "The pricing plan for COS."
}
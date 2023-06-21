variable "sm_instance_name" {
  description = "IBM Cloud Secrets Manager instance name"
  type        = string
}

variable "sm_instance_plan" {
  description = "IBM Cloud Secrets Manager instance plan."
  type        = string
  default = "trial"
}

variable "sm_instance_region" {
  description = "IBM Cloud Secrets Manager instance region"
  type        = string
}

variable "sm_secret_group_name" {
  description = "The name of your existing secret group."
  type        = string
}

variable "sm_secret_group_description" {
  description = "An extended description of your secret group.To protect your privacy, do not use personal data, such as your name or location, as a description for your secret group."
  type        = string
  default     = "Extended description for this group."
}

variable "cluster_name_or_id" {
    description = "IBM Cloud Kubernetes Cluster id or name"
    type = string
}

variable "sm_endpoint_type" {
  description = "IBM Cloud Secrets Manager secret endpoint type. Type is 'public' or 'private'."
  type        = string
  default = "public"
}

variable "sm_arbitrary_secret_name" {
  description = "IBM Cloud Secrets Manager arbitrary secret name"
  type        = string
}

variable "sm_arbitrary_secret_description" {
  description = "An extended description of your secret.To protect your privacy, do not use personal data, such as your name or location, as a description for your secret group."
  type        = string
}

variable "sm_arbitrary_secret_expiration_date" {
  description = "The date a secret is expired. The date format follows RFC 3339 (example: 2022-04-12T23:20:50.520Z)."
  type        = string
}

variable "sm_arbitrary_secret_labels" {
  description = "Labels that you can use to search for secrets in your instance. Up to 30 labels can be created."
  type        = list(string)
  default     = [ "dev", "stage" ]
}

variable "sm_arbitrary_secret_payload" {
  description = "The arbitrary secret's data payload."
  type        = string
  default     = "secret-credentials"
}

variable "opaque_secret_name" {
  description = "The opaque secret name."
  type        = string
}

variable "opaque_secret_namespace" {
  description = "The opaque secret namespace."
  type        = string
}

variable "cluster_name" {
  type        = string
  description = "Name of the IKS cluster"
  nullable    = false
}

variable "zone" {
  type = string
}

variable "worker_count" {
  type    = number
  default = 3
}

variable "pod_subnet" {
  type    = string
  default = "172.17.0.0/18"
}

variable "service_subnet" {
  type    = string
  default = "172.21.0.0/16"
}

locals {
  zone        = "eu-de-2"
  vpc_name    = "vpc-${var.cluster_name}"
  subnet_name = "sn-${var.cluster_name}"
  gw_name     = "pgw-${var.cluster_name}"
  cos_name    = "cos-${var.cluster_name}"
}

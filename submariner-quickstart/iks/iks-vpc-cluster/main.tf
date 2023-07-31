resource "ibm_is_vpc" "vpc" {
  name = local.vpc_name
}

resource "ibm_is_subnet" "subnet1" {
  name                     = local.subnet_name
  vpc                      = ibm_is_vpc.vpc.id
  total_ipv4_address_count = 256
  zone                     = var.zone
}

resource "ibm_is_public_gateway" "pgw" {
  name = local.gw_name
  vpc  = ibm_is_vpc.vpc.id
  zone = ibm_is_subnet.subnet1.zone
}

resource "ibm_is_subnet_public_gateway_attachment" "link-pgw-to-subnet1" {
  subnet         = ibm_is_subnet.subnet1.id
  public_gateway = ibm_is_public_gateway.pgw.id
}

data "ibm_container_cluster_versions" "cluster_versions" {}

locals {
  latest_iks_version = data.ibm_container_cluster_versions.cluster_versions.valid_kube_versions[length(data.ibm_container_cluster_versions.cluster_versions.valid_kube_versions) - 1]
}

resource "ibm_container_vpc_cluster" "cluster" {
  name         = var.cluster_name
  vpc_id       = ibm_is_vpc.vpc.id
  flavor       = var.instance_type
  worker_count = 3
  kube_version = local.latest_iks_version

  pod_subnet     = var.pod_subnet
  service_subnet = var.service_subnet

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/container_vpc_cluster#wait_till
  wait_till = "OneWorkerNodeReady"

  zones {
    name      = ibm_is_subnet.subnet1.zone
    subnet_id = ibm_is_subnet.subnet1.id
  }
}

output "info" {
  value = {
    id = ibm_container_vpc_cluster.cluster.id
    name = ibm_container_vpc_cluster.cluster.name
    pod_subnet = ibm_container_vpc_cluster.cluster.pod_subnet
    service_subnet = ibm_container_vpc_cluster.cluster.service_subnet
    vpc_id = ibm_is_vpc.vpc.id
  }
}

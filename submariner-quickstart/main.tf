terraform {
  required_version = ">=1.0.0, <2.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">=1.3.0, <2.0"
    }
  }
}

provider "ibm" {
  region = "eu-de"
}

variable "clusters" {
  type = list(object({
    name           = string
    pod_subnet     = string
    service_subnet = string
    zone           = string
  }))
  default = [
    {
      name           = "primary"
      pod_subnet     = "172.17.0.0/18"
      service_subnet = "172.21.0.0/16"
      zone           = "eu-de-2"
    },
    {
      name           = "secondary"
      pod_subnet     = "172.17.64.0/18"
      service_subnet = "172.22.0.0/16"
      zone           = "eu-de-3"
    }
  ]
}

module "clusters" {
  source   = "./iks-vpc-cluster"
  for_each = { for cluster in var.clusters : cluster.name => cluster }

  cluster_name   = "submariner-demo-${each.key}"
  zone           = each.value.zone
  pod_subnet     = each.value.pod_subnet
  service_subnet = each.value.service_subnet
}

output "clusters" {
  value = module.clusters
}

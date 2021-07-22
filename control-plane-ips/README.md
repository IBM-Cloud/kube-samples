# Control plane IP addresses

If you use [Calico pre-DNAT network policies](https://cloud.ibm.com/docs/containers?topic=containers-network_policies), [VPC security groups](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#security_groups), [VPC access control lists (ACLs)](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#acls), or another custom firewall to block incoming traffic to your cluster, you must allow inbound access on TCP port 80 from the IBM Cloud Kubernetes Service or Red Hat OpenShift on IBM Cloud control plane subnets to the IP addresses of your ALBs or routers so they can be health checked.

> Note: For classic clusters only, you must also allow inbound traffic from [Akamai's source IP addresses](https://github.com/IBM-Cloud/kube-samples/tree/master/akamai/gtm-liveness-test){: external}.

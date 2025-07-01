# IBM NS1 Connect Health-Monitor Firewall Rules

To secure your IBM Cloud Kubernetes Service or Red Hat OpenShift on IBM Cloud cluster, you might use [Calico pre-DNAT network policies](https://cloud.ibm.com/docs/containers?topic=containers-network_policies), [VPC security groups](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#security_groups), [VPC access control lists (ACLs)](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#acls), or another custom firewall solution to block incoming traffic to Ingress or router services.

To ensure that the NS1 Connect health-monitor can check the health of your ALBs of routers, you must allow inbound access from the following NS1 IP addresses.

 - `163.114.225.0/24`
 - `163.114.230.0/24`
 - `163.114.231.0/24`

To use HTTP protocol, allow inbound traffic through port 80. If you configure your ALBs or routers to listen for the HTTPS protocol, allow inbound traffic through port 443. Use the [`ibmcloud ks nlb-dns monitor configure` command](https://cloud.ibm.com/docs/containers?topic=containers-cli-plugin-kubernetes-service-cli#cs_nlb-dns-monitor-configure) to configure the protocol to be used.

For more information see the [IBM NS1 Connect Documentation on monitoring](https://www.ibm.com/docs/en/ns1-connect?topic=monitoring).

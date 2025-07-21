# Akamai GTM Firewall Rules

To secure your IBM Cloud Kubernetes Service or Red Hat OpenShift on IBM Cloud cluster, you might use [Calico pre-DNAT network policies](https://cloud.ibm.com/docs/containers?topic=containers-network_policies), [VPC security groups](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#security_groups), [VPC access control lists (ACLs)](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#acls), or another custom firewall solution to block incoming traffic to Ingress or router services.

To ensure that the Akamai Global Traffic Management liveness test can check the health of your ALBs or routers, you must allow inbound access from the relevant Akamai IP addresses. The list of these IP addresses, and related documentation are moved to our documentation. Check out the section that fits your setup:
 - [IBM Cloud Kubernetes Service (Classic)](https://cloud.ibm.com/docs/containers?topic=containers-firewall#firewall-ingress-domain-monitor)
 - [IBM Cloud Kubernetes Service (VPC)](https://cloud.ibm.com/docs/containers?topic=containers-vpc-firewall#firewall-ingress-domain-monitor)
 - [RedHat OpenShift on IBM Cloud (Classic)](https://cloud.ibm.com/docs/openshift?topic=openshift-firewall#firewall-ingress-domain-monitor)
 - [RedHat OpenShift on IBM Cloud (VPC)](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-firewall#firewall-ingress-domain-monitor)

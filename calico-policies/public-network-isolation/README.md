# Public network Calico policies

This set of Calico policies work in conjunction with the [default Calico policies](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#default_policy) to protect public network traffic of a cluster while allowing communication on the public network that is necessary for the cluster to function. The policies target the public interface (eth1) and the pod network of a cluster.

For more information on how to use these policies, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#isolate_workers_public).

## Regions

The Calico policies are organized by region. Choose the directory for the region that your cluster is in when applying these policies.

## Summary of changes made by the Calico policies

Along with the default Calico policies that are applied to the public interface of worker nodes, the Calico policies in this set configure the public network for worker node and pods as follows:

**Worker nodes**

* Egress network traffic on the public network interface for worker nodes is permitted to the following ports:
  * TCP/UDP 53 for DNS
  * TCP/UDP 2049 for communication with NFS file servers
  * TCP/UDP 443 and 3260 for communication to block storage
  * TCP/UDP 443 on 172.21.0.1 for the Kubernetes master API server local proxy
  * TCP/UDP 2040 and 2041 on 172.20.0.0 for the etcd local proxy
  * Specified ports for other IBM Cloud services
* Ingress network traffic on the public network interface for worker nodes is permitted only from subnets for IBM Cloud infrastructure to manage worker nodes through the following ports:
  * TCP/UDP 53 for DNS
  * TCP/UDP 52311 for Big Fix
  * ICMP to allow infrastructure health monitoring
  * VRRP to use load balancer services

**Pods**

* Egress network traffic on the public network interface for pods is permitted to the following ports:
  * TCP/UDP 53 for DNS
  * TCP/UDP 2049 for communication with NFS file servers
  * TCP/UDP 443 and 3260 for communication to block storage
  * TCP/UDP 443 on 172.21.0.1 for the Kubernetes master API server local proxy
  * TCP/UDP 2040 and 2041 on 172.20.0.0 for the etcd local proxy
  * TCP/UDP 20000:32767 and 443 for communication with the Kubernetes master
  * Specified ports for other IBM Cloud services
* Ingress network traffic on the public network interface for pods is permitted from network load balancer (NLB), Ingress application load balancer (ALB), and NodePort services.

> When you apply the egress pod policies that are included in this policy set, only network traffic to the subnets and ports that are specified in the pod policies is permitted. All traffic to any subnets or ports that are not specified in the policies is blocked for all pods in all namespaces. Because only the ports and subnets that are necessary for the pods to function in IBM Cloud Kubernetes Service are specified in these policies, your pods cannot send network traffic over the internet until you add or change the Calico policy to allow them to.

## List of Calico policies

### Required policies

|Policy name|Description|
|-----------|-----------|
| `allow-egress-pods-public` | Opens ports that are necessary for pods to function properly and allows pods to communicate with other pods in the cluster. |
| `allow-ibm-ports-public` | Opens ports that are necessary for worker nodes to function properly. |
| `allow-public-service-endpoint` | Allows worker nodes to communicate with the cluster master through the public service endpoint. |
| `deny-all-outbound-public` | Denies all egress from worker nodes. Because this policy has a high order, `1850`, its rule is applied last in the chain of Iptables rules that an outgoing packet from a worker node matches against. Other policies in this set have lower orders, so if an outgoing packet matches one of those rules, the packet is permitted. The `deny-all-outbound` policy ensures that if an outgoing packet does not match any polices as it moves through the Iptables rules chain, the packet is denied by this policy. Note that this policy has a lower order then the default policy `allow-all-outbound`.|

### Optional policies

|Policy name|Description|
|-----------|-----------|
| `allow-public-services` | Allows workers to access specified IBM Cloud services over the public network. |
| `allow-public-services-pods` | Allows pods to access specified IBM Cloud services over the public network. |

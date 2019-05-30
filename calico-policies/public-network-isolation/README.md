# Public network Calico policies

This set of Calico policies work in conjunction with the [default Calico host policies](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#default_policy) to protect public network traffic of a cluster while allowing communication on the public network that is necessary for the cluster to function. The policies target the public interface (eth1) and the pod network of a cluster.

For more information on how to use these policies, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#isolate_workers_public).

## Summary of changes made by the Calico policies

**Worker nodes**

* Egress from workers on the public interface is permitted to port 10250 for VPN communication between master and workers, port 53 for DNS, port 2049 for communication with NFS file servers, ports 443 and 3260 for communication to block storage, port 2040 for the master API server local proxy, port 2041 for the etcd local proxy, and ports 20000:32767 and 443 for communication with the master. You can optionally allow worker communication to other IBM Cloud services.
* Ingress to workers on the public interface is permitted only from subnets for IBM Cloud Infrastructure (Softlayer) systems that are used to manage worker nodes. This ingress is permitted only through UPD/TCP port 53 for DNS access, port 52311 for Big Fix, port 10250 for VPN communication between master and workers, ICMP to allow infrastructure health monitoring, and VRRP to use load balancer services.

**Pods**

* Egress from pods on the public interface is permitted to port 53 for DNS access, port 2049 for communication with NFS file servers, and ports 443 and 3260 for communication to block storage. You can optionally allow pod communication to other IBM Cloud services.
* Ingress to pods on the public interface is permitted from network load balancer (NLB), Ingress application load balancer (ALB), and NodePort services.

## List of Calico policies

|Policy name|Description|
|-----------|-----------|
| `allow-egress-pods-public` | Opens ports that are necessary for pods to function properly, allows pods to communicate with other pods in the cluster, and optionally allows pod access to specified IBM Cloud services. |
| `allow-ibm-ports-public` | Opens ports that are necessary for worker nodes to function properly. |
| `allow-public-service-endpoint` | Allows worker nodes to communicate with the cluster master through the public service endpoint. |
| `allow-public-services` | Allows workers to access specified IBM Cloud services over the public network. |
| `deny-all-outbound-public` | Denies all egress from worker nodes. Because this policy has a high order, `1850`, its rule is applied last in the chain of Iptables rules that an outgoing packet from a worker node matches against. Other policies in this set have lower orders, so if an outgoing packet matches one of those rules, the packet is permitted. The `deny-all-outbound` policy ensures that if an outgoing packet does not match any polices as it moves through the Iptables rules chain, the packet is denied by this policy. |

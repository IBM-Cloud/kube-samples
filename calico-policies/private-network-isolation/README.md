# Private network Calico policies

This set of Calico policies and host endpoints isolate the private network traffic of a cluster from other resources in the account's private network, while allowing communication on the private network that is necessary for the cluster to function. The policies target the private interface (eth0) and the pod network of a cluster.

For more information on how to use these policies, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#isolate_workers).

## Calico version

Clusters that run Kubernetes version 1.9 or later must use Calico v3 syntax.

## Regions

The Calico policies are organized by region. Choose the directory for the region that your cluster is in when applying these policies.

## Summary of changes made by the Calico policies

**Worker nodes**
* Egress network traffic on the private network interface for worker nodes is permitted to the following ports:
  * TCP/UDP 53 for DNS
  * TCP/UDP 2049 for communication with NFS file servers
  * TCP/UDP 443 and 3260 for communication to block storage
  * TCP/UDP 443 on 172.21.0.1 for the Kubernetes master API server local proxy
  * TCP/UDP 2040 and 2041 on 172.20.0.0 for the etcd local proxy
  * Specified ports for other {{site.data.keyword.Bluemix_notm}} services
* Ingress network traffic on the private network interface for worker nodes is permitted only from subnets for {[softlayer]} to manage worker nodes through the following ports:
  * TCP/UDP 53 for DNS
  * TCP/UDP 52311 for Big Fix
  * 10250 for VPN communication between the Kubernetes master and worker nodes
  * ICMP to allow infrastructure health monitoring
  * VRRP to use load balancer services

**Pods**
* Egress network traffic on the private network interface for pods to private networks is denied. If worker nodes are connected to a public VLAN, pod egress is permitted to public networks. All other pod egress on the private network interface is permitted to the following ports:
  * TCP/UDP 53 for DNS
  * TCP/UDP 2049 for communication with NFS file servers
  * TCP/UDP 443 and 3260 for communication to block storage
  * TCP/UDP 443 on 172.21.0.1 for the Kubernetes master API server local proxy
  * TCP/UDP 2040 and 2041 on 172.20.0.0 for the etcd local proxy
  * TCP/UDP 20000:32767 and 443 for communication with the Kubernetes master
  * Specified ports for other {{site.data.keyword.Bluemix_notm}} services
* Ingress network traffic on the private network interface for pods is permitted from workers in the cluster.

## List of Calico policies

### Required policies

|Policy name|Description|
|-----------|-----------|
| `allow-all-workers-private` | Limits worker node communication on the private network to other worker nodes and pods within the cluster. |
| `allow-egress-pods-private` | Opens ports that are necessary for pods to function properly and allows pods to communicate with other pods in the cluster. Also blocks pod egress to the `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16` private networks. If worker nodes are connected to a public VLAN, pod egress is permitted to public networks. |
| `allow-ibm-ports-private` | Opens ports that are necessary for worker nodes to function properly. |
| `allow-icmp-private`| Opens the ICMP protocol to allow infrastructure health monitoring. |
| `allow-private-service-endpoint` | Allows worker nodes to communicate with the cluster master through the private service endpoint. |
| `allow-sys-mgmt-private` | Allows egress to the IBM Cloud Classic infrastructure private subnets so that you can create worker nodes in your cluster. |
| `generic-privatehostendpoint` | Sets up private host endpoints for your worker nodes so that the other policies in this set can target the worker node private interface (eth0) of worker nodes. **Note:** Each time you add a worker node to a cluster, you must update the host endpoints file with the new entries. |

### Optional policies

|Policy name|Description|
|-----------|-----------|
| `allow-private-services` | Allows workers to access other IBM Cloud services that support communication over the private network through private service endpoints. |
| `allow-private-services-pods` | Allows pods to access other IBM Cloud services that support communication over the private network through private service endpoints. |
| `allow-vrrp-private` | Opens the VRRP protocol to use Kubernetes load balancer services. |

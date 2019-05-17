# Private network Calico policies

This set of Calico policies and host endpoints isolate the private network traffic of a cluster from other resources in the account's private network, while allowing communication on the private network that is necessary for the cluster to function. The policies target the private interface (eth0) and the pod network of a cluster.

For more information on how to use these policies, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#isolate_workers).

## Calico version

Clusters that run Kubernetes version 1.9 or later must use Calico v3 syntax.

## Summary of changes made by the Calico policies

**Worker nodes**

* Egress from workers on the private interface is permitted to other workers and pod IPs on workers in the cluster, the UPD/TCP port 53 for DNS access, port 2049 for communication with NFS file servers, ports 443 and 3260 for communication to block storage, port 2040 for the master API server local proxy, port 2041 for the etcd local proxy, and ports 20000:32767 and 443 for communication with the master. You can optionally allow worker communication to other {{site.data.keyword.Bluemix_notm}} services by applying the `allow-private-services` policy.
* Ingress to workers on the private interface is permitted only from other workers in the cluster and subnets for {[softlayer]} systems that are used to manage worker nodes. This ingress is permitted only through UPD/TCP port 53 for DNS access, port 10250 for VPN communication between master and workers, ICMP to allow infrastructure health monitoring, and optionally VRRP to use load balancer services.

**Pods**

* Ingress to pods on the private interface is permitted from workers in the cluster.
* Egress from pods on the private interface is restricted only to port 53 for DNS, port 10250 for VPN communication between the master and pods, and other pods in the cluster. You can optionally block pod egress to private networks by applying the `deny-egress-pods-private` policy.

## List of Calico policies

### Required policies

|Policy name|Description|
|-----------|-----------|
| `generic-privatehostendpoint` | Sets up private host endpoints for your worker nodes so that the other policies in this set can target the worker node private interface (eth0) of worker nodes. **Note:** Each time you add a worker node to a cluster, you must update the host endpoints file with the new entries. |
| `allow-all-workers-private` | Limits worker node communication on the private network to other worker nodes and pods on those worker nodes within the cluster. |
| `allow-egress-pods-private` | Opens port 10250 for VPN communication between the master and pods and port 53 for DNS. |
| `allow-ibm-ports-private` | Opens port 10250 for VPN communication between the master and worker nodes, port 53 for DNS, port 2049 for communication with NFS file servers, ports 443 and 3260 for communication to block storage, port 2040 for the master API server local proxy, and port 2041 for the etcd local proxy. |
| `allow-icmp-private`| Opens the ICMP protocol to allow infrastructure health monitoring. |
| `allow-private-service-endpoint` | Allows worker nodes to communicate with the cluster master through the private service endpoint. |
| `allow-sys-mgmt-private` | Allows egress to the IBM Cloud Infrastructure (Softlayer) private subnets so that you can create worker nodes in your cluster. |

### Optional policies

|Policy name|Description|
|-----------|-----------|
| `allow-private-services` | Allows workers to access other IBM Cloud services that support communication over the private network through private service endpoints. |
| `allow-vrrp-private` | Opens the VRRP protocol to use Kubernetes load balancer services. |
| `deny-egress-pods-private` | Blocks pod egress to the `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16` private networks. |

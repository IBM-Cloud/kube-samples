# Private network Calico policies

This set of Calico policies and host endpoints isolate the private network traffic of a cluster from other resources in the account's private network, while allowing communication on the private network that is necessary for the cluster to function. The policies target the private interface (eth0) and the pod network of a cluster.

For more information on how to use these policies, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#isolate_workers).

## Calico version

Clusters that run Kubernetes version 1.9 or later must use Calico v3 syntax.

## Regions

The Calico policies are organized by region. Choose the directory for the region that your cluster is in when applying these policies.

## Summary of changes made by the Calico policies

**Worker nodes**

* Egress from workers on the private interface is permitted to other workers and pod IPs on workers in the cluster, the UPD/TCP port 53 for DNS access, port 2049 for communication with NFS file servers, ports 443 and 3260 for communication to block storage, port 2040 for the master API server local proxy, port 2041 for the etcd local proxy, port 52311 for IBM BigFix worker updates, and ports 20000:32767 and 443 for communication with the master. You can optionally allow worker communication to other {{site.data.keyword.Bluemix_notm}} services by applying the `allow-private-services` policy.
* Ingress to workers on the private interface is permitted only from other workers in the cluster and subnets for {[softlayer]} systems that are used to manage worker nodes. This ingress is permitted only through UPD/TCP port 53 for DNS access, port 10250 for VPN communication between master and workers, ICMP to allow infrastructure health monitoring, and optionally VRRP to use load balancer services.

**Pods**

* Egress from pods on the public interface is permitted to port 53 for DNS access, port 2049 for communication with NFS file servers, ports 443 and 3260 for communication to block storage, port 10250 for VPN communication, port 2040 and 2041 on 172.20.0.0 for the master API server local proxy, to the cluster master, and to other pods in the cluster. Access to private networks is denied.
* Ingress to pods on the private interface is permitted from workers in the cluster.

## List of Calico policies

### Required policies

|Policy name|Description|
|-----------|-----------|
| `allow-all-workers-private` | Limits worker node communication on the private network to other worker nodes and pods on those worker nodes within the cluster. |
| `allow-egress-pods-private` | Opens ports that are necessary for pods to function properly and allows pods to communicate with other pods in the cluster. Also blocks pod egress to the `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16` private networks. |
| `allow-ibm-ports-private` | Opens ports that are necessary for worker nodes to function properly. |
| `allow-icmp-private`| Opens the ICMP protocol to allow infrastructure health monitoring. |
| `allow-private-service-endpoint` | Allows worker nodes to communicate with the cluster master through the private service endpoint. |
| `allow-sys-mgmt-private` | Allows egress to the IBM Cloud Infrastructure (Softlayer) private subnets so that you can create worker nodes in your cluster. |
| `generic-privatehostendpoint` | Sets up private host endpoints for your worker nodes so that the other policies in this set can target the worker node private interface (eth0) of worker nodes. **Note:** Each time you add a worker node to a cluster, you must update the host endpoints file with the new entries. |

### Optional policies

|Policy name|Description|
|-----------|-----------|
| `allow-private-services` | Allows workers to access other IBM Cloud services that support communication over the private network through private service endpoints. |
| `allow-vrrp-private` | Opens the VRRP protocol to use Kubernetes load balancer services. |

# Private network Calico policies

This set of Calico policies and host endpoints isolate the private network traffic of a cluster from other resources in the account's private network, while allowing communication on the private network that is necessary for the cluster to function. The policies target the private interface (eth0) and the pod network of a cluster.

> NOTE: Upcoming change to folder structure of the private network Calico policies. We are removing the empty `calico-v3` directory to match the public network policy structure. The v3 folder will be removed on 20 May 2022. The change will be merged with PR: https://github.com/IBM-Cloud/kube-samples/pull/195

For more information on how to use these policies, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#isolate_workers).

> NOTE: If your worker nodes are attached to both a public and private VLAN, a public NodePort is still open on every worker node. In addition to these policies, you can also create a [Calico preDNAT network policy to block traffic to the public NodePorts](https://cloud.ibm.com/docs/containers?topic=containers-network_policies#block_ingress).

## Regions

The Calico policies are organized by region. Choose the directory for the region that your cluster is in when applying these policies.

> NOTE: The policies in the ca-tor and br-sao directories are meant for use with the Toronto and São Paulo multizone locations. For the Toronto single zone location, use the policies in the us-east directory instead. For the São Paulo single zone location, use the policies in the us-south directory instead.

## Deployment Notes

These policies specify worker node egress to `172.30.0.0/16` as the default pod subnet. If you specified a custom pod subnet when you created a classic cluster, or if you use a VPC cluster (which doesn't use the standard pod subnet by default), you must edit the `allow-all-workers-private.yaml` policy to change `172.30.0.0/16` to the pod subnet CIDR for this cluster instead. To find your cluster's pod subnet, run `ibmcloud ks cluster get -c <cluster_name_or_ID>`.

## Summary of changes made by the Calico policies

**Worker nodes**
* Egress network traffic on the private network interface for worker nodes is permitted to the following ports:
  * TCP/UDP 53 and 5353 for OpenShift version 4.3 or later for DNS
  * TCP/UDP 2049 for communication with NFS file servers
  * TCP/UDP 3260 for communication to block storage
  * TCP/UDP 443 on 172.21.0.1 (or 10.10.10.1 for clusters created more than 3 years ago) for the Kubernetes master API server local proxy
  * TCP/UDP 2040 and 2041 on 172.20.0.0 for the etcd local proxy
  * Specified ports for other IBM Cloud services
* Ingress network traffic on the private network interface for worker nodes is permitted only from subnets for IBM Cloud Infrastructure to manage worker nodes through the following ports:
  * TCP/UDP 53 and 5353 for OpenShift version 4.3 or later for DNS
  * TCP/UDP 52311 for Big Fix
  * 10250 for VPN communication between the Kubernetes master and worker nodes
  * ICMP to allow infrastructure health monitoring
  * VRRP to use load balancer services

**Pods**
* Egress network traffic on the private network interface for pods to private networks is denied. If worker nodes are connected to a public VLAN, pod egress is permitted to public networks. All other pod egress on the private network interface is permitted to the following ports:
  * TCP/UDP 53 and 5353 for OpenShift version 4.3 or later for DNS
  * TCP/UDP 2049 for communication with NFS file servers
  * TCP/UDP 3260 for communication to block storage
  * TCP/UDP 443 on 172.21.0.1 (or 10.10.10.1 for clusters created more than 3 years ago) for the Kubernetes master API server local proxy
  * TCP/UDP 2040 and 2041 on 172.20.0.0 for the etcd local proxy
  * TCP/UDP 20000:32767 and 443 for communication with the Kubernetes master
  * TCP 4443 for metrics-server for Kubernetes version 1.19 or later, or TCP 6443 for OpenShift version 4.3 or later
  * Specified ports for other IBM Cloud services
* Ingress network traffic on the private network interface for pods is permitted from workers in the cluster.

> **IMPORTANT**: When you apply the egress pod policies that are included in this policy set, only network traffic to the subnets and ports that are specified in the pod policies is permitted. All traffic to any subnets or ports that are not specified in the policies is blocked for all pods in all namespaces. Because only the ports and subnets that are necessary for the pods to function in IBM Cloud Kubernetes Service are specified in these policies, your pods cannot send network traffic over the private network until you add or change the Calico policy to allow them to. For example, if you use any in-cluster webhooks, you must add policies to ensure that the webhooks can make the required connections. You also must create policies for any non-local services that extend the Kubernetes API. You can find these services by running `kubectl get apiservices`. For OpenShift clusters, `default/openshift-apiserver` is included as a local service and does not require a network policy.

## List of Calico policies

### Required policies

|Policy name|Description|
|-----------|-----------|
| `allow-all-workers-private` | Limits worker node communication on the private network to other worker nodes and pods within the cluster. |
| `allow-egress-pods-private` | Opens ports that are necessary for pods to function properly and allows pods to communicate with other pods in the cluster. Also blocks pod egress to the `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16` private networks. If worker nodes are connected to a public VLAN, pod egress is permitted to public networks. |
| `allow-ibm-ports-private` | Opens ports that are necessary for worker nodes to function properly. |
| `allow-icmp-private`| Opens the ICMP protocol to allow infrastructure health monitoring. |
| `allow-private-service-endpoint` | Allows worker nodes to communicate with the cluster master through the private service endpoint. |
| `allow-sys-mgmt-private` | Allows egress and ingress to the IBM Cloud Classic infrastructure private subnets so that you can create worker nodes in your cluster. |
| `generic-privatehostendpoint` | **OpenShift 3.11 clusters only**: Sets up private host endpoints for your worker nodes so that the other policies in this set can target the worker node private interface (eth0) of worker nodes. Each time you add a worker node to a cluster, you must update the host endpoints file with the new entries. |
| `deny-all-private-default` | Denies all ingress to and egress from worker nodes on the private network. Because this policy has a high order, its rule is applied last in the chain of Iptables rules that an outgoing packet from a worker node matches against. Other policies in this set have lower orders, so if an outgoing packet matches one of those rules, the packet is permitted. The `deny-all-private-default` policy ensures that if traffic does not match any policies as it moves through the Iptables rules chain, the packet is denied by this policy.|

### Optional policies

|Policy name|Description|
|-----------|-----------|
| `allow-private-services` | Allows workers to access other IBM Cloud services that support communication over the private network through private service endpoints. |
| `allow-private-services-pods` | Allows pods to access other IBM Cloud services that support communication over the private network through private service endpoints. |
| `allow-vrrp-private` | Opens the VRRP protocol to use Kubernetes load balancer services. |


### Other files
|Policy name|Description|
|-----------|-----------|
| `private-ips.md` | Include a raw list of the private IPs needed to allow worker nodes to communicate with the cluster master through the private service endpoint. |

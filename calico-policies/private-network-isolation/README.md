# Private network Calico policies

This set of Calico policies and host endpoints isolate the private network traffic of a cluster in IBM Cloud Kubernetes from other resources in the account's private network. The policies target the private interface (eth0) and the pod network of a cluster.

**Note:** Each time you add a worker node to a cluster, you must update the host endpoints file with the new entries.

## List of changes made by the Calico policies

Worker node summary:
 - Private interface Egress only allowed to pod IPs, workers in this cluster, and udp/tcp port 53 (dns).
 - Private interface Ingress only allowed from workers in the cluster, dns, kubelet, icmp, and vrrp.

Pod specific summary (i.e. pods not on the host network):
 - Allow all ingress to pods. The above worker ingress restrictions limit this to traffic coming from workers in the cluster.
 - Allow egress to public IPs, dns, kubelet, and other pods in the cluster.
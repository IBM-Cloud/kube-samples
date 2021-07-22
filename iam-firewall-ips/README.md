# IAM firewall IP addresses

By default, all IP addresses can be used to log in to the IBM Cloud console and access your cluster. In the IBM Cloud Identity and Access Management (IAM) console, you can generate a firewall by [creating an allowlist by specifying which IP addresses have access](https://cloud.ibm.com/docs/account?topic=account-ips), and all other IP addresses are restricted. If you use an IAM firewall, you must add the CIDRs of the IBM Cloud Kubernetes Service or Red Hat OpenShift on IBM Cloud control plane for the zones in the region where your cluster is located to the allowlist. You must allow these CIDRs so that the control plane can create Ingress ALBs and `LoadBalancers` in your cluster.

For more information, see the [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-firewall#iam_allowlist) or [Red Hat OpenShift on IBM Cloud](https://cloud.ibm.com/docs/openshift?topic=openshift-firewall#iam_allowlist) documentation.

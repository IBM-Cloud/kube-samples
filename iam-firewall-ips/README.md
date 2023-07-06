# IAM firewall IP addresses

By default, all IP addresses can be used to log in to the IBM Cloud console and access your cluster. In the IBM Cloud Identity and Access Management (IAM) console, you can generate a firewall by [creating an allowlist by specifying which IP addresses have access](https://cloud.ibm.com/docs/account?topic=account-ips), and all other IP addresses are restricted. If you use an IAM firewall, you must add the CIDRs of the IBM Cloud Kubernetes Service or Red Hat OpenShift on IBM Cloud control plane for the zones in the region where your cluster is located to the allowlist. You must allow these CIDRs so that the control plane can create Ingress ALBs and `LoadBalancers` in your cluster.

Choose the file for the region that your cluster's zones are located in.
* `dal` (Dallas, US South, us-south): sao01, sjc03, sjc04, dal10, dal12, dal13
* `fra` (Frankfurt, EU Central, eu-de): ams03, mil01, par01, fra02, fra04, fra05
* `lon` (London, UK South, eu-gb): lon02, lon04, lon05, lon06
* `osa` (Osaka, jp-osa): osa21, osa22, osa23
* `sao` (São Paulo, br-sao): sao01, sao04, sao05
* `syd` (Sydney, AP South, ap-south): syd01, syd04, syd05
* `tok` (Tokyo, AP North, jp-tok): che01, sng01, tok02, tok04, tok05
* `tor` (Toronto, ca-tor): tor01, tor04, tor05
* `wdc` (Washington DC, US East, us-east): mon01, tor01, wdc04, wdc06, wdc07

> NOTE: The policies in the `tor` and `sao` directories are meant for use with the Toronto and São Paulo multizone locations. For the Toronto single zone location, use the policies in the `wdc` directory instead. For the São Paulo single zone location, use the policies in the `dal` directory instead.

For more information, see the [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-firewall#iam_allowlist) or [Red Hat OpenShift on IBM Cloud](https://cloud.ibm.com/docs/openshift?topic=openshift-firewall#iam_allowlist) documentation.

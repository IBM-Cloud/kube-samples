# Control plane IP addresses

If you use [Calico pre-DNAT network policies](https://cloud.ibm.com/docs/containers?topic=containers-network_policies), [VPC security groups](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#security_groups), [VPC access control lists (ACLs)](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#acls), or another custom firewall to block incoming traffic to your cluster, you must allow inbound access on TCP port 80 from the IBM Cloud Kubernetes Service or Red Hat OpenShift on IBM Cloud control plane subnets to the IP addresses of your ALBs or routers so they can be health checked. Note that for classic clusters only, you must also allow inbound traffic from [Akamai's source IP addresses](https://github.com/IBM-Cloud/kube-samples/tree/master/akamai/gtm-liveness-test).

Choose the file for the region that your cluster's zones are located in. 
* `dal` (Dallas, US South, us-south): hou02, mex01, sao01, sjc03, sjc04, dal10, dal12, dal13
* `fra` (Frankfurt, EU Central, eu-de): ams03, mil01, osl01, par01, fra02, fra04, fra05
* `lon` (London, UK South, eu-gb): lon02, lon04, lon05, lon06
* `osa` (Osaka, jp-osa): osa21, osa22, osa23
* `sao` (São Paulo, br-sao): sao01, sao04, sao05
* `syd` (Sydney, AP South, ap-south): syd01, syd04, syd05
* `tok` (Tokyo, AP North, jp-tok): che01, hkg02, seo01, sng01, tok02, tok04, tok05
* `tor` (Toronto, ca-tor): tor01, tor04, tor05
* `wdc` (Washington DC, US East, us-east): mon01, tor01, wdc04, wdc06, wdc07

> NOTE: The policies in the `tor` and `sao` directories are meant for use with the Toronto and São Paulo multizone locations. For the Toronto single zone location, use the policies in the `wdc` directory instead. For the São Paulo single zone location, use the policies in the `dal` directory instead.

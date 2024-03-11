# Akamai GTM Firewall Rules

To secure your IBM Cloud Kubernetes Service or Red Hat OpenShift on IBM Cloud cluster, you might use [Calico pre-DNAT network policies](https://cloud.ibm.com/docs/containers?topic=containers-network_policies), [VPC security groups](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#security_groups), [VPC access control lists (ACLs)](https://cloud.ibm.com/docs/containers?topic=containers-vpc-network-policy#acls), or another custom firewall solution to block incoming traffic to Ingress or router services.

To ensure that the Akamai Global Traffic Management liveness test can check the health of your ALBs or routers, you must allow inbound access from the following Akamai IP addresses. To use the default HTTP protocol, allow inbound traffic through port 80. If you configure your ALBs or routers to listen for the HTTPS protocol, such as with the [`ibmcloud ks nlb-dns monitor configure` command](https://cloud.ibm.com/docs/containers?topic=containers-cli-plugin-kubernetes-service-cli#cs_nlb-dns-monitor-configure), allow inbound traffic through port 443. 

For more information see the [Akamai GTM Documentation](https://learn.akamai.com/en-us/webhelp/global-traffic-management/global-traffic-management-user-guide/GUID-C1995591-5D7D-42B9-B54F-0CF6C7BD2532.html).

|Service Name             |CIDR Block         |Port   |
|-------------------------|-------------------|-------|
|Global Traffic Management|193.108.155.118/32 |80,443 |
|Global Traffic Management|8.18.43.199/32     |80,443 |
|Global Traffic Management|8.18.43.240/32     |80,443 |
|Global Traffic Management|66.198.8.167/32    |80,443 |
|Global Traffic Management|66.198.8.168/32    |80,443 |
|Global Traffic Management|67.220.143.216/31  |80,443 |
|Global Traffic Management|173.205.7.116/31   |80,443 |
|Global Traffic Management|209.249.98.36/31   |80,443 |
|Global Traffic Management|207.126.104.118/31 |80,443 |
|Global Traffic Management|63.217.211.110/31  |80,443 |
|Global Traffic Management|63.217.211.116/31  |80,443 |
|Global Traffic Management|204.2.159.68/31    |80,443 |
|Global Traffic Management|209.107.208.188/31 |80,443 |
|Global Traffic Management|124.40.41.200/29   |80,443 |
|Global Traffic Management|125.252.224.36/31  |80,443 |
|Global Traffic Management|125.56.219.52/31   |80,443 |
|Global Traffic Management|192.204.11.4/31    |80,443 |
|Global Traffic Management|204.1.136.238/31   |80,443 |
|Global Traffic Management|204.2.160.182/31   |80,443 |
|Global Traffic Management|204.201.160.246/31 |80,443 |
|Global Traffic Management|205.185.205.132/31 |80,443 |
|Global Traffic Management|220.90.198.178/31  |80,443 |
|Global Traffic Management|60.254.173.30/31   |80,443 |
|Global Traffic Management|61.111.58.82/31    |80,443 |
|Global Traffic Management|63.235.21.192/31   |80,443 |
|Global Traffic Management|64.145.89.236/31   |80,443 |
|Global Traffic Management|65.124.174.194/31  |80,443 |
|Global Traffic Management|69.31.121.20/31    |80,443 |
|Global Traffic Management|69.31.138.100/31   |80,443 |
|Global Traffic Management|77.67.85.52/31     |80,443 |
|Global Traffic Management|203.69.138.120/30  |80,443 |
|Global Traffic Management|66.198.26.68/30    |80,443 |
|Global Traffic Management|201.33.187.68/30   |80,443 |
|Global Traffic Management|2.16.0.0/13        |80,443 |
|Global Traffic Management|23.0.0.0/12        |80,443 |
|Global Traffic Management|23.192.0.0/11      |80,443 |
|Global Traffic Management|23.32.0.0/11       |80,443 |
|Global Traffic Management|23.64.0.0/14       |80,443 |
|Global Traffic Management|23.72.0.0/13       |80,443 |
|Global Traffic Management|69.192.0.0/16      |80,443 |
|Global Traffic Management|72.246.0.0/15      |80,443 |
|Global Traffic Management|88.221.0.0/16      |80,443 |
|Global Traffic Management|92.122.0.0/15      |80,443 |
|Global Traffic Management|95.100.0.0/15      |80,443 |
|Global Traffic Management|96.16.0.0/15       |80,443 |
|Global Traffic Management|96.6.0.0/15        |80,443 |
|Global Traffic Management|104.64.0.0/10      |80,443 |
|Global Traffic Management|118.214.0.0/16     |80,443 |
|Global Traffic Management|173.222.0.0/15     |80,443 |
|Global Traffic Management|184.24.0.0/13      |80,443 |
|Global Traffic Management|184.50.0.0/15      |80,443 |
|Global Traffic Management|184.84.0.0/14      |80,443 |

## Change History

|Date                  |Action | CIDR Block     |
|----------------------|-------|----------------|
|2023-05-16 00:00:00.0 |delete | 172.232.0.0/13 |

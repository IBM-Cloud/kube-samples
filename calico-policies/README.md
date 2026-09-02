# Calico policies

This folder contains sample Calico policies. They only apply to classic clusters, and they are just examples which are intended as a starting point and must be edited to meet your unique use cases.
- private-network-isolation: Provides Calico policies for controlling access to your cluster on the private network from other resources that you might have on the same private network.
- public-network-isolation: Provides Calico policies for controlling access to your cluster on the public network.

For information about allowing or denying traffic from a list of IP addresses, blocking traffic to NodePorts, and more, see the [Using Calico network policies to block traffic](https://cloud.ibm.com/docs/containers?topic=containers-policy_tutorial#policy_tutorial) tutorial and the [Controlling traffic with network policies](https://cloud.ibm.com/docs/containers?topic=containers-network_policies) steps in the IBM Cloud Kubernetes Service documentation.

# ibm-k8s-controller-config

IBM Cloud Kubernetes Service clusters are deployed with a ConfigMap (`kube-system/ibm-k8s-controller-config`) that contains the default managed configuration for application load balancers (ALBs). Occasionally IKS adjusts the ConfigMap values, you can always find the latest version in this repository (see [`ibm-k8s-controller-config.yaml`](./ibm-k8s-controller-config.yaml)).

Read more about IBM Cloud Kubernetes Service ALBs in [our documentation](https://cloud.ibm.com/docs/containers?topic=containers-ingress-about). Find more details about the possible configuration values in [nginx-ingress' documentation](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/).

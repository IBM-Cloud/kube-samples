#!/bin/bash

# Stop script on first error
set -e

# Include helper functions
source helper.sh

# Using a new kube config file (will be cleaned up)
rm -f clusters.kube
export KUBECONFIG="$(pwd)/clusters.kube"

# Download cluster admin accounts
clusters="$(jq ".outputs.clusters.value[].info.name" terraform.tfstate -r)"
for cluster in $clusters; do
  ibmcloud ks cluster config --admin --cluster $cluster
done

# Obtain kubectl context names
contexts="$(kubectl config get-contexts -oname)"
primary_ctx=$(kubectl config get-contexts -oname | head -1)
secondary_ctx=$(kubectl config get-contexts -oname | tail -n 1)

#############################################
### Download the latest stable subctl
#############################################

if [[ ! -f subctl ]]; then
  export DESTDIR="$(pwd)"
  curl -Ls https://get.submariner.io | bash
fi

./subctl version

#############################################
### Set up Calico CNI
#############################################

# Setup cross-cluster-subnet NAT avoidance
# https://submariner.io/operations/deployment/calico/
kubectl apply --context $primary_ctx -f resources/calico-no-nat.primary.yaml
kubectl apply --context $secondary_ctx -f resources/calico-no-nat.secondary.yaml

#############################################
### Deploy broker
#############################################

# manual: https://submariner.io/operations/deployment/subctl/
./subctl deploy-broker --context $primary_ctx
# it creates the `broker-info.subm` file

wait_for_pod $primary_ctx name=submariner-operator

#############################################
### Select Submariner gateways
#############################################

for ctx in $contexts; do
  # select the first node as gateway
  node=$(kubectl get node --context $ctx -o jsonpath='{.items[0].metadata.name}')
  kubectl --context $ctx label node $node submariner.io/gateway=true
done

###########################################
### Joining the first cluster
###########################################

# manual: https://submariner.io/operations/deployment/subctl/
./subctl join \
  --context $primary_ctx \
  broker-info.subm \
  --clusterid primary \
  --insecure-skip-tls-verify=true \
  --check-broker-certificate=false \
  --force-udp-encaps \
  --load-balancer

###########################################
### Setup load balancer for tunnels
###########################################

wait_for_loadbalancer_creation $primary_ctx

healthcheck_port=$(
  kubectl --context $primary_ctx \
    get service -n=submariner-operator \
    submariner-gateway \
    -o jsonpath='{.spec.healthCheckNodePort}'
)

# NLB reference: https://cloud.ibm.com/docs/containers?topic=containers-vpc-lbaas#setup_vpc_nlb
kubectl --context $primary_ctx annotate service \
    -n submariner-operator submariner-gateway \
    --overwrite \
    service.beta.kubernetes.io/aws-load-balancer-type- \
    service.kubernetes.io/ibm-load-balancer-cloud-provider-enable-features=nlb \
    service.kubernetes.io/ibm-load-balancer-cloud-provider-ip-type=public \
    service.kubernetes.io/ibm-load-balancer-cloud-provider-vpc-health-check-protocol=http \
    service.kubernetes.io/ibm-load-balancer-cloud-provider-vpc-health-check-port=$healthcheck_port

# it can take a while
wait_for_ready_loadbalancer $primary_ctx

wait_for_pod $primary_ctx app=submariner-gateway

###########################################
### Joining the second cluster
###########################################

./subctl join \
  --context $secondary_ctx \
  broker-info.subm \
  --insecure-skip-tls-verify=true \
  --check-broker-certificate=false \
  --force-udp-encaps \
  --clusterid secondary

wait_for_pod $secondary_ctx app=submariner-gateway

###########################################
### Additional fixes
###########################################

# Configure reverse path filtering on the nodes
for ctx in $contexts; do
  kubectl apply --context $ctx -f resources/submariner-calico-rpfilter-setter.yaml
done

### Cross enable "external" pod subnets

function cluster_ids() {
  jq ".outputs.clusters.value[].info.id" terraform.tfstate -r
}
primary_cluster=$(cluster_ids | head -1)
secondary_cluster=$(cluster_ids | tail -n 1)
ibmcloud is security-group-rule-add "kube-$primary_cluster" inbound all "172.17.64.0/18"
ibmcloud is security-group-rule-add "kube-$secondary_cluster" inbound all "172.17.0.0/18"

##################################################################

cat <<EOM

Congratulations!
You have two fresh clusters interconnected with Submariner.

Run ./30_verify.sh to test the new installation.

EOM

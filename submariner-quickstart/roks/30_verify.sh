#!/bin/bash

# Stop script on first error
set -e

export KUBECONFIG="$(pwd)/clusters.kube"

primary_ctx=$(kubectl config get-contexts -oname | head -1)
secondary_ctx=$(kubectl config get-contexts -oname | tail -n 1)

get_gw_status() {
  kubectl get --context=$primary_ctx \
      -n submariner-operator \
      gateways.submariner.io \
      -o jsonpath="{.items[0].status$*}" \
      2>/dev/null
}

status=$(get_gw_status '.connections[0].status' || true)
if [[ "$status" != "connected" ]]; then
    cat <<EOM
Submariner gateway is NOT connected yet. It can take a while (maybe an hour).

Otherwise, issue the following command to check that the status block has a connection:
kubectl get --context=$primary_ctx -n submariner-operator gateways.submariner.io -o yaml
If no connection is present there, then it might be that the 2nd cluster is not joined or set up.

Waiting on tunnel to be established.
EOM

  while true; do
    status=$(get_gw_status '.connections[0].status' || true)
    [[ "$status" == "connected" ]] && break
    echo -n .
    sleep 10
  done
  echo
fi

echo "Gateway tunnel is established."

echo "Running connectivitiy tests..."

./subctl verify \
  --context $primary_ctx \
  --tocontext $secondary_ctx \
  --insecure-skip-tls-verify=true \
  --only connectivity

echo "Connectivitiy tests are DONE"

echo "Running service discovery tests..."

./subctl verify --only service-discovery \
  --context $primary_ctx \
  --tocontext $secondary_ctx \
  --insecure-skip-tls-verify=true \
  --only service-discovery

# Overview of the settings and statuses:
#   subctl show all --context $primary_ctx

# In case of something is off:
#   subctl diagnose all

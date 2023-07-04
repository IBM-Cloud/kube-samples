#!/bin/bash

wait_for_pod() {
  ctx=$1
  selector=$2

  while true; do
    pod=$(kubectl get pod --context=$ctx -A -oname --selector $selector)
    if [[ "$pod" != "" ]]; then
      break
    fi
    echo "Waiting for pod to start: $selector"
    sleep 3
  done

  echo "Waiting for pod to be ready: $pod"

  kubectl wait --context=$ctx \
    --namespace=submariner-operator \
    --for=condition=Ready \
    --timeout=5m $pod
}

wait_for_loadbalancer() {
  echo "Waiting for the loadbalancer to be set up (can be more than 10 minutes)"
  while true; do
    ip=$(
      kubectl --context $primary_ctx \
        get service -n=submariner-operator submariner-gateway \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    )
    if [[ "$ip" != "" ]]; then
      echo -e "\nLoadbalancer is ready"
      break
    fi
    echo -n .
    sleep 10
  done
  echo
}

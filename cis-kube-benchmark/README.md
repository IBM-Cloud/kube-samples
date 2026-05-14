# Running the `cis-kube-benchmark` sample

## Creating the configmap

Before running a CIS Benchmark sample, create a configmap that holds the configuration files:

```shell
kubectl create namespace ibm-kube-bench-test

# Adjust paths to the correct CIS Benchmark version:
kubectl create configmap -n ibm-kube-bench-test kube-bench-node \
  --from-file=config.yaml="cis-kube-benchmark/cis-1.12/ibm/config.yaml" \
  --from-file=node.yaml="cis-kube-benchmark/cis-1.12/ibm/node.yaml"
```

## Running the job

Apply the manifests, wait for the job to complete, and inspect the results:

```shell
# Adjust path to the correct CIS Benchmark version:
kubectl apply -f cis-kube-benchmark/cis-1.12/ibm/job-node.yaml

# Fetch the results when the job is complete:
kubectl logs -n ibm-kube-bench-test -l job-name=kube-bench-node --tail -1
```

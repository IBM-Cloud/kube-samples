# iks-workerpool-reboot

> **Note:** This is a community sample provided for reference. It is not an officially supported
> IBM product — please test it in a non-production environment before using it in production.

## About

`safe-reboot-workerpool.sh` performs a **rolling, no-SSH reboot** of every node in an IBM Cloud Kubernetes Service (IKS) worker pool. It uses `kubectl` to cordon and drain nodes and the **IBM Cloud CLI (`ibmcloud ks worker reboot`)** to trigger the actual reboot — no direct node access or privileged pods are required.

Each node is cordoned, drained, rebooted via the IBM Cloud API, and uncordoned in sequence. The cluster retains capacity throughout because only one node is taken offline at a time.

## Prerequisites

- `kubectl` configured and authenticated against your target cluster.
- `ibmcloud` CLI installed and logged in, with the IKS plugin (`ibmcloud plugin install kubernetes-service`).
- Sufficient RBAC permissions to cordon/uncordon nodes.
- The target worker pool nodes must be labelled with `ibm-cloud.kubernetes.io/worker-pool-name=<pool>` (default on all IKS worker pools).
- The nodes must carry the `ibm-cloud.kubernetes.io/worker-id` label (set automatically by IKS).

## Usage

```bash
./safe-reboot-workerpool.sh <cluster-name-or-id> <worker-pool-name>
```

**Example:**

```bash
./safe-reboot-workerpool.sh my-cluster default
```

Progress and any errors are written to both stdout and `./k8s-safe-reboot.log` in the current directory.

## How it works

For each node in the worker pool, the script performs the following steps in order:

### Step 1 — Discover nodes
Queries `kubectl get nodes` filtered by the IBM Cloud label `ibm-cloud.kubernetes.io/worker-pool-name=<pool>` to build the list of nodes to reboot.

### Step 2 — Resolve worker ID
Reads the `ibm-cloud.kubernetes.io/worker-id` label from the node object to obtain the IBM Cloud worker ID required by the `ibmcloud ks worker reboot` command.

### Step 3 — Cordon
Marks the node as unschedulable (`kubectl cordon`) so no new pods are scheduled onto it during the maintenance window.

### Step 4 — Drain
Evicts all running workloads off the node (`kubectl drain`) with a 60-second grace period and a 15-minute overall timeout. DaemonSet pods and empty-dir data are handled automatically.

### Step 5 — Reboot
Issues `ibmcloud ks worker reboot --cluster <cluster> --worker <worker-id> -f` to reboot the node through the IBM Cloud API — no privileged pods or SSH required.

### Step 6 — Wait for NotReady
Polls the node's `Ready` condition every 5 seconds (up to 5 minutes) until it is no longer `True`, confirming the reboot has started.

### Step 7 — Wait for Ready
Polls the node's `Ready` condition every 10 seconds (up to 15 minutes) until it returns to `True`, confirming the OS is back up and the kubelet has re-registered.

### Step 8 — Uncordon
Marks the node schedulable again (`kubectl uncordon`).

The script then moves on to the next node and repeats the process.

## Configuration

The following constants at the top of the script can be adjusted to match your cluster's behaviour:

| Variable | Default | Description |
|---|---|---|
| `POLL_INTERVAL_NOT_READY` | `5`s | How often to check if the node has gone NotReady |
| `POLL_INTERVAL_READY` | `10`s | How often to check if the node has come back Ready |
| `TIMEOUT_NOT_READY` | `300`s | Maximum time to wait for a node to go NotReady |
| `TIMEOUT_READY` | `900`s | Maximum time to wait for a node to become Ready |

## Error handling

- If a node fails at any step (including an unresolvable worker ID or a failed `ibmcloud ks worker reboot` call), a warning is logged and the script **continues** with the remaining nodes (rolling behaviour, not all-or-nothing).
- After all nodes are processed, a summary of any failed nodes is printed and the script exits with code `1` if there were failures, or `0` if all nodes rebooted successfully.

# iks-workerpool-reboot

## About

`safe-reboot-workerpool.sh` performs a **rolling, no-SSH reboot** of every node in an IBM Cloud Kubernetes Service (IKS) worker pool. It uses the Kubernetes API exclusively — no direct node access or IBM Cloud CLI commands are required.

Each node is cordoned, drained, rebooted via a short-lived privileged pod, and uncordoned in sequence. The cluster retains capacity throughout because only one node is taken offline at a time.

## Prerequisites

- `kubectl` configured and authenticated against your target cluster.
- Sufficient RBAC permissions to cordon/uncordon nodes and create privileged pods.
- The target worker pool nodes must be labelled with `ibm-cloud.kubernetes.io/worker-pool-name=<pool>` (default on all IKS worker pools).

## Usage

```bash
./safe-reboot-workerpool.sh <worker-pool-name>
```

**Example:**

```bash
./safe-reboot-workerpool.sh default
```

Progress and any errors are written to both stdout and `./k8s-safe-reboot.log` in the current directory.

## How it works

For each node in the worker pool, the script performs the following steps in order:

### Step 1 — Discover nodes
Queries `kubectl get nodes` filtered by the IBM Cloud label `ibm-cloud.kubernetes.io/worker-pool-name=<pool>` to build the list of nodes to reboot.

### Step 2 — Cordon
Marks the node as unschedulable (`kubectl cordon`) so no new pods are scheduled onto it during the maintenance window.

### Step 3 — Drain
Evicts all running workloads off the node (`kubectl drain`) with a 60-second grace period and a 15-minute overall timeout. DaemonSet pods and empty-dir data are handled automatically.

### Step 4 — Reboot
Creates a short-lived privileged Kubernetes pod pinned to the node via `nodeName`. The pod uses `nsenter -t 1 -m -u -i -n reboot` to enter the host's PID 1 namespaces and invoke the system `reboot` command — no SSH required.

### Step 5 — Wait for NotReady
Polls the node's `Ready` condition every 5 seconds (up to 5 minutes) until it is no longer `True`, confirming the reboot has started.

### Step 6 — Wait for Ready
Polls the node's `Ready` condition every 10 seconds (up to 15 minutes) until it returns to `True`, confirming the OS is back up and the kubelet has re-registered.

### Step 7 — Uncordon
Marks the node schedulable again (`kubectl uncordon`) and cleans up the reboot pod.

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

- If a node fails at any step, a warning is logged and the script **continues** with the remaining nodes (rolling behaviour, not all-or-nothing).
- After all nodes are processed, a summary of any failed nodes is printed and the script exits with code `1` if there were failures, or `0` if all nodes rebooted successfully.
- Leftover reboot pods from interrupted previous runs are cleaned up automatically before each node reboot, making re-runs safe.

#!/bin/bash

# ============================================================
# Safe reboot all nodes in IBM Cloud worker pool via Kubernetes
# No SSH required
# Usage: ./safe-reboot-workerpool.sh <worker-pool-name>
# ============================================================

set -euo pipefail

WORKER_POOL="${1:-}"
LOG_FILE="./k8s-safe-reboot.log"

# ============================================================
# Colours — stdout only; log file always gets plain text
# ============================================================
readonly CLR_RESET='\033[0m'
readonly CLR_INFO='\033[0;36m'    # cyan
readonly CLR_WARN='\033[0;33m'    # yellow
readonly CLR_ERROR='\033[0;31m'   # red

# ============================================================
# Configuration — tune these to match your cluster's behaviour
# ============================================================
readonly POLL_INTERVAL_NOT_READY=5   # seconds between NotReady status checks
readonly POLL_INTERVAL_READY=10      # seconds between Ready status checks
readonly TIMEOUT_NOT_READY=300       # max seconds to wait for node to go NotReady (5 min)
readonly TIMEOUT_READY=900           # max seconds to wait for node to become Ready (15 min)

if [ -z "$WORKER_POOL" ]; then
  echo "Usage: $0 <worker-pool-name>"
  exit 1
fi

# ============================================================
# log_info / log_warn / log_error <message>
# Writes a timestamped, colour-coded message to stdout and
# a plain-text copy to the log file.
# ============================================================
_log() {
  local colour="$1"
  local level="$2"
  local msg="$3"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  # Coloured output to stdout
  printf "${colour}%s [%-5s] %s${CLR_RESET}\n" "$ts" "$level" "$msg"
  # Plain text to log file
  printf "%s [%-5s] %s\n" "$ts" "$level" "$msg" >> "$LOG_FILE"
}

log_info()  { _log "${CLR_INFO}"  "INFO"  "$1"; }
log_warn()  { _log "${CLR_WARN}"  "WARN"  "$1"; }
log_error() { _log "${CLR_ERROR}" "ERROR" "$1"; }

# ============================================================
# get_nodes
# Returns space-separated node names belonging to WORKER_POOL.
# IBM Cloud labels nodes with:
#   ibm-cloud.kubernetes.io/worker-pool-name=<pool>
# ============================================================
get_nodes() {
  kubectl get nodes \
    -l "ibm-cloud.kubernetes.io/worker-pool-name=${WORKER_POOL}" \
    -o jsonpath='{.items[*].metadata.name}'
}

# ============================================================
# wait_for_node_not_ready <node-name>
# Polls until the node's Ready condition is no longer "True".
# Returns 0 on success, 1 on timeout.
# ============================================================
wait_for_node_not_ready() {
  local node_name="$1"
  local -r max_attempts=$(( TIMEOUT_NOT_READY / POLL_INTERVAL_NOT_READY ))
  local attempt=0
  local status

  log_info "Waiting for ${node_name} to go NotReady (timeout: ${TIMEOUT_NOT_READY}s)..."

  while (( attempt < max_attempts )); do
    # Capture both stdout and stderr; suppress kubectl errors from breaking the loop
    if ! status=$(kubectl get node "${node_name}" \
        -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>&1); then
      log_warn "kubectl error while checking ${node_name}: ${status}"
      (( attempt++ ))
      sleep "${POLL_INTERVAL_NOT_READY}"
      continue
    fi

    if [[ "${status}" != "True" ]]; then
      log_info "${node_name} is NotReady (detected after $(( attempt * POLL_INTERVAL_NOT_READY ))s)"
      return 0
    fi

    (( attempt++ ))
    sleep "${POLL_INTERVAL_NOT_READY}"
  done

  log_error "Timed out waiting for ${node_name} to go NotReady after ${TIMEOUT_NOT_READY}s"
  return 1
}

# ============================================================
# wait_for_node_ready <node-name>
# Polls until the node's Ready condition is "True".
# Returns 0 on success, 1 on timeout.
# ============================================================
wait_for_node_ready() {
  local node_name="$1"
  local -r max_attempts=$(( TIMEOUT_READY / POLL_INTERVAL_READY ))
  local attempt=0
  local status

  log_info "Waiting for ${node_name} to become Ready (timeout: ${TIMEOUT_READY}s)..."

  while (( attempt < max_attempts )); do
    # Capture both stdout and stderr; suppress kubectl errors from breaking the loop
    if ! status=$(kubectl get node "${node_name}" \
        -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>&1); then
      log_warn "kubectl error while checking ${node_name}: ${status}"
      (( attempt++ ))
      sleep "${POLL_INTERVAL_READY}"
      continue
    fi

    if [[ "${status}" == "True" ]]; then
      log_info "${node_name} is Ready (detected after $(( attempt * POLL_INTERVAL_READY ))s)"
      return 0
    fi

    (( attempt++ ))
    sleep "${POLL_INTERVAL_READY}"
  done

  log_error "Timed out waiting for ${node_name} to become Ready after ${TIMEOUT_READY}s"
  return 1
}

# ============================================================
# reboot_node <node-name>
# Cordons, drains, reboots, and uncordons a single node.
# Returns 0 on success, 1 if any step fails.
# ============================================================
reboot_node() {
  local node_name="$1"
  local pod_name="reboot-${node_name}"

  log_info "================================================"
  log_info "Starting reboot for node: ${node_name}"

  log_info "Cordoning ${node_name}"
  kubectl cordon "${node_name}"

  log_info "Draining ${node_name}"
  kubectl drain "${node_name}" \
    --ignore-daemonsets \
    --delete-emptydir-data \
    --grace-period=60 \
    --timeout=15m

  # Remove any leftover reboot pod from a previous interrupted run
  kubectl delete pod "${pod_name}" --ignore-not-found 2>/dev/null || true

  log_info "Triggering reboot via Kubernetes privileged pod"
  if ! kubectl run "${pod_name}" \
      --image=agnhost \
      --restart=Never \
      --overrides="
{
  \"spec\": {
    \"nodeName\": \"${node_name}\",
    \"hostPID\": true,
    \"hostNetwork\": true,
    \"containers\": [
      {
        \"name\": \"reboot\",
        \"image\": \"us.icr.io/armada-master/agnhost:2.52\",
        \"securityContext\": {
          \"privileged\": true
        },
        \"command\": [\"nsenter\"],
        \"args\": [\"-t\",\"1\",\"-m\",\"-u\",\"-i\",\"-n\",\"reboot\"]
      }
    ]
  }
}"; then
    log_error "Failed to create reboot pod for ${node_name}"
    return 1
  fi

  if ! wait_for_node_not_ready "${node_name}"; then
    log_error "${node_name} did not go NotReady — skipping uncordon. Manual intervention may be required."
    return 1
  fi

  if ! wait_for_node_ready "${node_name}"; then
    log_error "${node_name} did not return to Ready — skipping uncordon. Manual intervention required."
    return 1
  fi

  log_info "Uncordoning ${node_name}"
  kubectl uncordon "${node_name}"

  kubectl delete pod "${pod_name}" --ignore-not-found

  log_info "Reboot completed successfully for ${node_name}"
  return 0
}

# ============================================================
# MAIN
# ============================================================

log_info "Starting rolling reboot of worker pool: ${WORKER_POOL}"

NODES=$(get_nodes)

if [[ -z "${NODES}" ]]; then
  log_error "No nodes found in worker pool '${WORKER_POOL}'. Check the pool name and your kubeconfig."
  exit 1
fi

failed_nodes=()

for node in ${NODES}; do
  if ! reboot_node "${node}"; then
    log_warn "Reboot failed for ${node} — continuing with remaining nodes"
    failed_nodes+=("${node}")
  fi
done

if (( ${#failed_nodes[@]} > 0 )); then
  log_error "Worker pool reboot completed WITH ERRORS. Failed nodes: ${failed_nodes[*]}"
  exit 1
fi

log_info "Worker pool reboot completed successfully"

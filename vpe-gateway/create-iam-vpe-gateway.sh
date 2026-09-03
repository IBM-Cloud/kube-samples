#!/usr/bin/env bash
# create-iam-vpe-gateway.sh
#
# Creates or removes the VPE Gateway for IAM in a VPC that contains an
# IBM Kubernetes Service or Red Hat OpenShift on IBM Cloud cluster.
#
# Usage:
#   ./create-iam-vpe-gateway.sh add    [--vpc <name-or-id>] [--subnets <id1,id2,...>]
#   ./create-iam-vpe-gateway.sh remove [--vpc <name-or-id>]

set -uo pipefail

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

ACTION=""
VPC_ARG=""
SUBNETS_ARG=""

if [[ $# -lt 1 ]]; then
  echo "ERROR: No action specified. Usage: $0 add|remove [--vpc <name-or-id>] [--subnets <id1,id2,...>]" >&2
  exit 1
fi

ACTION="$1"
shift

if [[ "$ACTION" != "add" && "$ACTION" != "remove" ]]; then
  echo "ERROR: Invalid action '$ACTION'. The first argument must be 'add' or 'remove'." >&2
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vpc)
      VPC_ARG="$2"
      shift 2
      ;;
    --subnets)
      SUBNETS_ARG="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown parameter '$1'." >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate prerequisites
# ---------------------------------------------------------------------------

# Check ibmcloud login and region
IBMCLOUD_TARGET_OUTPUT=$(ibmcloud target 2>&1) || true

if echo "$IBMCLOUD_TARGET_OUTPUT" | grep -q "Not logged in"; then
  echo "ERROR: You are not logged in to the IBM Cloud CLI. Run 'ibmcloud login' and then target the region that contains your VPC cluster before running this script." >&2
  exit 1
fi

# Check jq
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: 'jq' is required but not found. Install it before running this script." >&2
  exit 1
fi

# Check plugins — capture once to avoid two slow calls
# Strip ANSI escape sequences that ibmcloud may embed even with --output json
PLUGIN_LIST_JSON=$(ibmcloud plugin list --output json 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g') || PLUGIN_LIST_JSON="[]"
if ! echo "$PLUGIN_LIST_JSON" | jq -e '.[] | select(.Name == "vpc-infrastructure" or (.Aliases // [] | contains(["vpc-infrastructure"])))' >/dev/null 2>&1; then
  echo "ERROR: The 'is' (vpc-infrastructure) plugin is not installed. Install it with: ibmcloud plugin install vpc-infrastructure" >&2
  exit 1
fi
if ! echo "$PLUGIN_LIST_JSON" | jq -e '.[] | select(.Name == "container-service" or (.Aliases // [] | contains(["container-service"])))' >/dev/null 2>&1; then
  echo "ERROR: The 'ks' (container-service) plugin is not installed. Install it with: ibmcloud plugin install kubernetes-service" >&2
  exit 1
fi

# Check region
REGION=$(echo "$IBMCLOUD_TARGET_OUTPUT" | grep -E "^Region:" | awk '{print $2}' || true)
if [[ -z "$REGION" || "$REGION" == "No" ]]; then
  echo "ERROR: No region is targeted. Run 'ibmcloud target -r <region>' to target the region that contains your VPC cluster." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Resolve and validate the VPC
# ---------------------------------------------------------------------------

# NOTE: `ibmcloud ks clusters --output json` omits the `vpcs` field and others.
# So here we fetch each cluster individually with `cluster get` which returns the full 
# JSON, then we combine the results
CLUSTER_LIST_JSON=$(ibmcloud ks clusters --provider vpc-gen2 --output json 2>&1)
FULL_LIST_CLUSTER_IDS=$(echo "$CLUSTER_LIST_JSON" | jq -r '.[].id' 2>/dev/null || true)
ALL_CLUSTERS_JSON="[]"
while IFS= read -r _cid; do
  [[ -z "$_cid" ]] && continue
  _CLUSTER_DETAIL=$(ibmcloud ks cluster get -c "$_cid" --output json 2>/dev/null)
  ALL_CLUSTERS_JSON=$(echo "$ALL_CLUSTERS_JSON" | jq --argjson c "$_CLUSTER_DETAIL" '. + [$c]')
done <<< "$FULL_LIST_CLUSTER_IDS"

# Filter to VPC clusters in the targeted region
VPC_CLUSTERS_JSON=$(echo "$ALL_CLUSTERS_JSON" | \
  jq --arg region "$REGION" '[.[] | select(.region == $region and .provider == "vpc-gen2")]')

VPC_CLUSTER_COUNT=$(echo "$VPC_CLUSTERS_JSON" | jq 'length')

if [[ "$VPC_CLUSTER_COUNT" -eq 0 ]]; then
  echo "ERROR: No VPC clusters were found in region '$REGION'. Target a region that contains a VPC cluster before running this script." >&2
  exit 1
fi

# Collect unique VPC IDs from the clusters
UNIQUE_VPC_IDS=$(echo "$VPC_CLUSTERS_JSON" | jq -r '[.[].vpcs[0]] | unique | .[]')
ALL_VPCS_JSON=$(ibmcloud is vpcs --output json 2>/dev/null)
if [[ -z "$VPC_ARG" ]]; then
  UNIQUE_VPC_COUNT=$(echo "$UNIQUE_VPC_IDS" | wc -l | tr -d ' ')
  if [[ "$UNIQUE_VPC_COUNT" -gt 1 ]]; then
    # Build human-readable list of VPC names + IDs
    VPC_LIST=""
    while IFS= read -r vid; do
      vname=$(echo "$ALL_VPCS_JSON" | jq -r --arg id "$vid" '.[] | select(.id == $id) | .name' 2>/dev/null || echo "$vid")
      VPC_LIST="${VPC_LIST} ${vname} (${vid}),"
    done <<< "$UNIQUE_VPC_IDS"
    VPC_LIST="${VPC_LIST%,}"
    echo "ERROR: Multiple VPCs with clusters were found in region '$REGION'. Specify which VPC to use with the --vpc parameter." >&2
    echo "VPCs found:${VPC_LIST}" >&2
    exit 1
  fi

  VPC_ID=$(echo "$UNIQUE_VPC_IDS" | head -1)
  VPC_NAME=$(echo "$ALL_VPCS_JSON" | jq -r --arg id "$VPC_ID" '.[] | select(.id == $id) | .name')
  echo "INFO: Using VPC '$VPC_NAME' ($VPC_ID) — the only VPC with clusters in region '$REGION'."
else
  ACCOUNT=$(echo "$IBMCLOUD_TARGET_OUTPUT" | grep -E "^Account:" | sed 's/Account:[[:space:]]*//' || true)
  # Try match by ID first, then by name
  VPC_MATCH=$(echo "$ALL_VPCS_JSON" | jq --arg val "$VPC_ARG" 'first(.[] | select(.id == $val or .name == $val)) // empty')
  if [[ -z "$VPC_MATCH" || "$VPC_MATCH" == "null" ]]; then
    echo "ERROR: VPC '$VPC_ARG' was not found in account '$ACCOUNT' in region '$REGION'." >&2
    exit 1
  fi
  VPC_ID=$(echo "$VPC_MATCH" | jq -r '.id')
  VPC_NAME=$(echo "$VPC_MATCH" | jq -r '.name')
  # Verify the VPC has clusters
  if ! echo "$UNIQUE_VPC_IDS" | grep -qx "$VPC_ID"; then
    echo "ERROR: VPC '$VPC_NAME' ($VPC_ID) does not contain any VPC clusters in region '$REGION'. Provide a VPC that has a cluster." >&2
    exit 1
  fi
fi

# Clusters in the resolved VPC
VPC_CLUSTERS_JSON=$(echo "$VPC_CLUSTERS_JSON" | \
  jq --arg vpcid "$VPC_ID" '[.[] | select(.vpcs[0] == $vpcid)]')

# Collect resource group
RESOURCE_GROUP_NAMES=$(echo "$VPC_CLUSTERS_JSON" | jq -r '[.[].resourceGroupName] | unique | .[]')
RG_COUNT=$(echo "$RESOURCE_GROUP_NAMES" | wc -l | tr -d ' ')

if [[ "$RG_COUNT" -eq 1 ]]; then
  RESOURCE_GROUP_NAME="$RESOURCE_GROUP_NAMES"
else
  # Multiple resource groups — check targeted RG
  TARGETED_RG=$(echo "$IBMCLOUD_TARGET_OUTPUT" | grep -E "^Resource group:" | sed 's/Resource group:[[:space:]]*//' || true)
  if [[ -n "$TARGETED_RG" ]] && echo "$RESOURCE_GROUP_NAMES" | grep -qx "$TARGETED_RG"; then
    RESOURCE_GROUP_NAME="$TARGETED_RG"
    echo "INFO: Using resource group '$RESOURCE_GROUP_NAME' (matches targeted resource group and a cluster resource group)."
  else
    FIRST_CLUSTER_NAME=$(echo "$VPC_CLUSTERS_JSON" | jq -r '.[0].name')
    RESOURCE_GROUP_NAME=$(echo "$VPC_CLUSTERS_JSON" | jq -r '.[0].resourceGroupName')
    echo "INFO: Using resource group '$RESOURCE_GROUP_NAME' (from cluster '$FIRST_CLUSTER_NAME')."
  fi
fi

GATEWAY_NAME="kube-iam-${VPC_ID}"
IAM_TARGET_CRN="crn:v1:bluemix:public:iam-svcs:global:::endpoint:private.iam.cloud.ibm.com"

if [[ "$ACTION" == "remove" ]]; then
  # Note that we only remove an endpoint gateway if the name matches the one we create, so that we do not
  # delete one that a user created with a different name
  GATEWAY_JSON=$(ibmcloud is endpoint-gateways --vpc ${VPC_ID} --output json 2>/dev/null | \
    jq --arg name "$GATEWAY_NAME" --arg vpcid "$VPC_ID" \
    'first(.[] | select(.name == $name and .vpc.id == $vpcid)) // empty')

  if [[ -z "$GATEWAY_JSON" || "$GATEWAY_JSON" == "null" ]]; then
    echo "INFO: No IAM VPE Gateway named '$GATEWAY_NAME' was found in VPC '$VPC_NAME'. Nothing to remove."
    exit 0
  fi

  GATEWAY_ID=$(echo "$GATEWAY_JSON" | jq -r '.id')

  # Check whether kube-<vpcID> (the fallback SG) is on the gateway
  FALLBACK_SG_NAME="kube-${VPC_ID}"
  GATEWAY_HAS_FALLBACK_SG=$(echo "$GATEWAY_JSON" | \
    jq --arg sgname "$FALLBACK_SG_NAME" '[.security_groups[]? | select(.name == $sgname)] | length > 0')

  printf "WARNING: This will permanently delete the IAM VPE Gateway '%s'\nand its Reserved IPs.\n\nAfter deletion, 'private.iam.cloud.ibm.com' in this VPC will resolve to the\nIBM Cloud private service endpoint addresses (166.8.0.0/14 range) instead.\n\nAre you sure you want to proceed? [y/N]: " "$GATEWAY_NAME"
  read -r CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi

  DELETE_OUTPUT=$(ibmcloud is endpoint-gateway-delete "$GATEWAY_ID" --force 2>&1) || {
    echo "ERROR: Failed to delete gateway '$GATEWAY_NAME'. Output:" >&2
    echo "$DELETE_OUTPUT" >&2
    exit 1
  }

  # Clean up fallback SG rules if we used kube-<vpcID>
  if [[ "$GATEWAY_HAS_FALLBACK_SG" == "true" ]]; then
    CLUSTER_IDS=$(echo "$VPC_CLUSTERS_JSON" | jq -r '.[].id')
    while IFS= read -r cid; do
      CLUSTER_SG_NAME="kube-${cid}"
      RULE_IDS=$(ibmcloud is security-group "$CLUSTER_SG_NAME" --vpc ${VPC_ID} --output json 2>/dev/null | \
        jq -r '[.rules[]? | select(.name | startswith("kube-outbound-iam-vpegw-ip-zone-")) | .id] | .[]')
      if [[ -n "$RULE_IDS" ]]; then
        while IFS= read -r rid; do
          ibmcloud is sg-ruled "$CLUSTER_SG_NAME" "$rid" --vpc ${VPC_ID} --force 2>/dev/null || true
          echo "Deleted security group rule with id $rid from security group $CLUSTER_SG_NAME now that the associated IAM reserved IP was deleted"
        done <<< "$RULE_IDS"
      fi
    done <<< "$CLUSTER_IDS"
  fi

  printf "SUCCESS: IAM VPE Gateway '%s' and its Reserved IPs have been removed from VPC '%s'.\n\nThe 'private.iam.cloud.ibm.com' DNS name in this VPC will revert to resolving\nto the IBM Cloud private service endpoint addresses (166.8.0.0/14 range).\n" \
    "$GATEWAY_NAME" "$VPC_NAME"
  exit 0

else # User specified "add"

  # Note that we look for an existing endpoint gateway for IAM by the target CRN and not by name
  # in case the user created one with a different name.  One one can exist per VPC so if one
  # exists with any name, we need to exit the scrips
  EXISTING_GW_JSON=$(ibmcloud is endpoint-gateways --vpc ${VPC_ID} --output json 2>/dev/null | \
    jq --arg crn "$IAM_TARGET_CRN" --arg vpcid "$VPC_ID" \
    'first(.[] | select(.target.crn == $crn and .vpc.id == $vpcid)) // empty')

  if [[ -n "$EXISTING_GW_JSON" && "$EXISTING_GW_JSON" != "null" ]]; then
    EXISTING_GW_NAME=$(echo "$EXISTING_GW_JSON" | jq -r '.name')
    EXISTING_STATE=$(echo "$EXISTING_GW_JSON" | jq -r '.lifecycle_state')
    if [[ "$EXISTING_STATE" == "stable" ]]; then
      echo "INFO: An IAM VPE Gateway named '$EXISTING_GW_NAME' already exists in VPC '$VPC_NAME' and is stable. No action is needed."
      exit 0
    else
      echo "WARNING: An IAM VPE Gateway named '$EXISTING_GW_NAME' already exists in VPC '$VPC_NAME' but its lifecycle state is '$EXISTING_STATE'. Investigate before proceeding." >&2
      exit 1
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Determine the security group to attach (add only)
# ---------------------------------------------------------------------------

ALL_SGS_JSON=$(ibmcloud is security-groups --vpc ${VPC_ID} --output json 2>/dev/null)

PRIMARY_SG_NAME="kube-vpegw-${VPC_ID}"
FALLBACK_SG_NAME="kube-${VPC_ID}"

PRIMARY_SG_JSON=$(echo "$ALL_SGS_JSON" | jq --arg name "$PRIMARY_SG_NAME" 'first(.[] | select(.name == $name)) // empty')
FALLBACK_SG_JSON=$(echo "$ALL_SGS_JSON" | jq --arg name "$FALLBACK_SG_NAME" 'first(.[] | select(.name == $name)) // empty')

if [[ -n "$PRIMARY_SG_JSON" ]]; then
  SG_ID=$(echo "$PRIMARY_SG_JSON" | jq -r '.id')
  SG_NAME="$PRIMARY_SG_NAME"
  USED_FALLBACK_SG=false
  echo "INFO: Using security group '$SG_NAME' ($SG_ID)."
elif [[ -n "$FALLBACK_SG_JSON" ]]; then
  SG_ID=$(echo "$FALLBACK_SG_JSON" | jq -r '.id')
  SG_NAME="$FALLBACK_SG_NAME"
  USED_FALLBACK_SG=true
  echo "INFO: Security group '$PRIMARY_SG_NAME' not found. Using fallback security group '$SG_NAME' ($SG_ID)."
else
  echo "ERROR: Neither '$PRIMARY_SG_NAME' nor '$FALLBACK_SG_NAME' security groups were found in VPC '$VPC_NAME'. Something may be wrong with this VPC's cluster configuration. Cannot proceed." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Resolve subnets and zones (add only)
# ---------------------------------------------------------------------------

# Parallel arrays (bash 3 compatible — no associative arrays)
# SUBNET_ZONES[i], SUBNET_IDS[i], SUBNET_NAMES[i] are all indexed together.
SUBNET_ZONES=()
SUBNET_IDS=()
SUBNET_NAMES=()

# Helper: check whether a zone is already in SUBNET_ZONES
_zone_already_seen() {
  local z="$1"
  local i
  for i in "${!SUBNET_ZONES[@]}"; do
    [[ "${SUBNET_ZONES[$i]}" == "$z" ]] && return 0
  done
  return 1
}

if [[ -n "$SUBNETS_ARG" ]]; then
  ALL_SUBNETS_JSON=$(ibmcloud is subnets --vpc ${VPC_ID} --output json 2>/dev/null)
  IFS=',' read -ra SUBNET_INPUT_LIST <<< "$SUBNETS_ARG"
  for subnet_val in "${SUBNET_INPUT_LIST[@]}"; do
    subnet_val="${subnet_val// /}"
    SUBNET_MATCH=$(echo "$ALL_SUBNETS_JSON" | \
      jq --arg val "$subnet_val" --arg vpcid "$VPC_ID" \
      'first(.[] | select((.id == $val or .name == $val) and .vpc.id == $vpcid)) // empty')
    if [[ -z "$SUBNET_MATCH" || "$SUBNET_MATCH" == "null" ]]; then
      echo "ERROR: Subnet '$subnet_val' was not found in VPC '$VPC_NAME'." >&2
      exit 1
    fi
    subnet_id=$(echo "$SUBNET_MATCH" | jq -r '.id')
    subnet_name=$(echo "$SUBNET_MATCH" | jq -r '.name')
    subnet_zone=$(echo "$SUBNET_MATCH" | jq -r '.zone.name')
    if _zone_already_seen "$subnet_zone"; then
      echo "ERROR: More than one subnet was provided for zone '$subnet_zone'. Provide at most one subnet per zone." >&2
      exit 1
    fi
    echo "INFO: Found subnet zone $subnet_zone, id $subnet_id, and name $subnet_name"
    SUBNET_ZONES+=("$subnet_zone")
    SUBNET_IDS+=("$subnet_id")
    SUBNET_NAMES+=("$subnet_name")
  done
else
  # Auto-discover subnets from worker nodes
  CLUSTER_IDS=$(echo "$VPC_CLUSTERS_JSON" | jq -r '.[].id')
  while IFS= read -r cid; do
    WORKERS_JSON=$(ibmcloud ks workers --cluster "$cid" --output json 2>/dev/null)
      WORKER_PAIRS=$(echo "$WORKERS_JSON" | \
        jq -r '.[] | select(.networkInterfaces != null) | .networkInterfaces[0].subnetID + " " + .location' 2>/dev/null || true)
    while IFS=' ' read -r w_subnet_id w_zone; do
      [[ -z "$w_subnet_id" || -z "$w_zone" || "$w_subnet_id" == "null" || "$w_zone" == "null" ]] && continue
      if ! _zone_already_seen "$w_zone"; then
        SUBNET_ZONES+=("$w_zone")
        SUBNET_IDS+=("$w_subnet_id")
        SUBNET_NAMES+=("")  # resolved below
      fi
    done <<< "$WORKER_PAIRS"
  done <<< "$CLUSTER_IDS"

  if [[ ${#SUBNET_ZONES[@]} -eq 0 ]]; then
    echo "ERROR: Could not auto-discover any subnets from worker nodes in VPC '$VPC_NAME'. Specify subnets explicitly with --subnets." >&2
    exit 1
  fi

  # Resolve subnet names and fill in SUBNET_NAMES
  echo "INFO: Auto-discovered subnets for VPE Gateway Reserved IPs:"
  for zone in $(echo "${SUBNET_ZONES[@]}" | tr ' ' '\n' | sort); do
    # find position of this zone in SUBNET_ZONES
    for i in "${!SUBNET_ZONES[@]}"; do
      if [[ "${SUBNET_ZONES[$i]}" == "$zone" ]]; then
        sid="${SUBNET_IDS[$i]}"
        sname=$(ibmcloud is subnet "$sid" --output json 2>/dev/null | jq -r '.name')
        SUBNET_NAMES[$i]="$sname"
        echo "  Zone $zone: $sname ($sid)"
        break
      fi
    done
  done
fi

# ---------------------------------------------------------------------------
# Create the VPE Gateway (add only)
# ---------------------------------------------------------------------------

echo "INFO: Creating IAM VPE Gateway '$GATEWAY_NAME' in VPC '$VPC_NAME'..."

CREATE_GW_FAILED=false
CREATE_GW_OUTPUT=$(ibmcloud is endpoint-gateway-create \
  --vpc "$VPC_ID" \
  --target "$IAM_TARGET_CRN" \
  --name "$GATEWAY_NAME" \
  --sg "$SG_ID" \
  --resource-group-name "$RESOURCE_GROUP_NAME" \
  --dns-resolution-binding-mode disabled \
  --output json 2>&1) || CREATE_GW_FAILED=true

if [[ "$CREATE_GW_FAILED" == "true" ]]; then
  echo "ERROR: Failed to create VPE Gateway. Output:" >&2
  echo "$CREATE_GW_OUTPUT" >&2
  exit 1
fi

GATEWAY_ID=$(echo "$CREATE_GW_OUTPUT" | jq -r '.id')

if [[ -z "$GATEWAY_ID" || "$GATEWAY_ID" == "null" ]]; then
  echo "ERROR: Gateway created but could not parse gateway ID from output:" >&2
  echo "$CREATE_GW_OUTPUT" >&2
  exit 1
fi

echo "INFO: Created VPE Gateway '$GATEWAY_NAME' ($GATEWAY_ID)."

# ---------------------------------------------------------------------------
# Create Reserved IPs (and SG rules if using fallback SG) (add only)
# ---------------------------------------------------------------------------

VPC_ID_NO_DASHES="${VPC_ID//-/}"

# Parallel arrays for Reserved IP names and addresses (same index as SUBNET_ZONES/IDS/NAMES)
RIP_NAMES=()
RIP_ADDRESSES=()
for i in "${!SUBNET_ZONES[@]}"; do
  RIP_NAMES+=("")
  RIP_ADDRESSES+=("")
done

for zone in $(echo "${SUBNET_ZONES[@]}" | tr ' ' '\n' | sort); do
  # Find the index for this zone
  zone_idx=0
  for i in "${!SUBNET_ZONES[@]}"; do
    [[ "${SUBNET_ZONES[$i]}" == "$zone" ]] && zone_idx=$i && break
  done
  subnet_id="${SUBNET_IDS[$zone_idx]}"
  subnet_name="${SUBNET_NAMES[$zone_idx]}"
  zone_no_dashes="${zone//-/}"
  random_suffix=$(LC_ALL=C tr -dc 'a-f0-9' </dev/urandom 2>/dev/null | head -c 3)
  rip_name="iks-${zone_no_dashes}-iam-${VPC_ID_NO_DASHES}-${random_suffix}"

  CREATE_RIP_FAILED=false
  CREATE_RIP_OUTPUT=$(ibmcloud is subnet-reserved-ip-create "$subnet_id" \
    --name "$rip_name" \
    --auto-delete true \
    --target "$GATEWAY_ID" \
    --output json 2>&1) || CREATE_RIP_FAILED=true

  if [[ "$CREATE_RIP_FAILED" == "true" ]]; then
    echo "$CREATE_RIP_OUTPUT" >&2
    echo "ERROR: Failed to create Reserved IP for zone '$zone' on gateway '$GATEWAY_NAME' ($GATEWAY_ID). Correct the issue that prevented the Reserved IP creation, then re-run this script specifying remove so that the partially configured gateway is deleted along with any associated security group rules.  Then run the script again to create the VPE Gateway." >&2
    exit 1
  fi

  # The address field in the subnet-reserved-ip-create response is 0.0.0.0 until
  # the platform assigns a real IP. Poll the gateway's ips array until it resolves.
  RIP_ADDRESS="0.0.0.0"
  RIP_WAIT_SECS=0
  RIP_MAX_WAIT=180
  while [[ "$RIP_ADDRESS" == "0.0.0.0" && "$RIP_WAIT_SECS" -lt "$RIP_MAX_WAIT" ]]; do
    if [[ "$RIP_WAIT_SECS" -gt 0 ]]; then
      echo "INFO: Reserved IP '$rip_name' address not yet assigned (0.0.0.0), waiting... (${RIP_WAIT_SECS}s elapsed)"
      sleep 5
      RIP_WAIT_SECS=$((RIP_WAIT_SECS + 5))
    else
      RIP_WAIT_SECS=1  # sentinel so the sleep triggers on the next iteration
    fi
    RIP_ADDRESS=$(ibmcloud is endpoint-gateway "$GATEWAY_ID" --output json 2>/dev/null | \
      jq -r --arg name "$rip_name" '.ips[]? | select(.name == $name) | .address')
    RIP_ADDRESS="${RIP_ADDRESS:-0.0.0.0}"
  done
  if [[ "$RIP_ADDRESS" == "0.0.0.0" ]]; then
    echo "ERROR: Reserved IP '$rip_name' was still unassigned after ${RIP_MAX_WAIT}s. Correct the issue that prevented the Reserved IP assignment, then re-run this script specifying remove so that the partially configured gateway is deleted along with any associated security group rules.  Then run the script again to create the VPE Gateway." >&2
    exit 1
  fi
  RIP_NAMES[$zone_idx]="$rip_name"
  RIP_ADDRESSES[$zone_idx]="$RIP_ADDRESS"
  echo "INFO: Created Reserved IP '$rip_name' ($RIP_ADDRESS) in zone '$zone' on subnet '$subnet_name' ($subnet_id)."

  # Add per-cluster SG rules when using the fallback security group
  if [[ "$USED_FALLBACK_SG" == "true" ]]; then
    zone_number="${zone##*-}"
    CLUSTER_IDS=$(echo "$VPC_CLUSTERS_JSON" | jq -r '.[].id')
    while IFS= read -r cid; do
      RULE_NAME="kube-outbound-iam-vpegw-ip-zone-${zone_number}"
      CLUSTER_SG_NAME="kube-${cid}"

      SG_RULE_FAILED=false
      SG_RULE_OUTPUT=$(ibmcloud is sg-rulec "$CLUSTER_SG_NAME" outbound tcp \
        --port-min 443 --port-max 443 \
        --remote "$RIP_ADDRESS" \
        --vpc "$VPC_ID" \
        --name "$RULE_NAME" \
        --output json 2>&1) || SG_RULE_FAILED=true

      if [[ "$SG_RULE_FAILED" == "true" ]]; then
        echo "$SG_RULE_OUTPUT" >&2
        echo "ERROR: Failed to create security group rule in '$CLUSTER_SG_NAME' for $RIP_ADDRESS in zone $zone. Correct the issue that prevented the security group rule creation, then re-run this script specifying remove so that the partially configured gateway is deleted along with any associated security group rules.  Then run the script again to create the VPE Gateway." >&2
        exit 1
      fi

      echo "INFO: Created security group rule '$RULE_NAME' for $RIP_ADDRESS in $CLUSTER_SG_NAME."
    done <<< "$CLUSTER_IDS"
  fi
done

# ---------------------------------------------------------------------------
# Print success summary (add only)
# ---------------------------------------------------------------------------

echo ""
echo "SUCCESS: IAM VPE Gateway created successfully."
echo ""
echo "  Gateway name:    $GATEWAY_NAME"
echo "  Gateway ID:      $GATEWAY_ID"
echo "  VPC:             $VPC_NAME ($VPC_ID)"
echo "  Security group:  $SG_NAME ($SG_ID)"
echo "  Resource group:  $RESOURCE_GROUP_NAME"
echo "  Reserved IPs:"
for zone in $(echo "${SUBNET_ZONES[@]}" | tr ' ' '\n' | sort); do
for i in "${!SUBNET_ZONES[@]}"; do
  if [[ "${SUBNET_ZONES[$i]}" == "$zone" ]]; then
    echo "    Zone $zone: ${RIP_ADDRESSES[$i]} (${RIP_NAMES[$i]}) on subnet ${SUBNET_NAMES[$i]} (${SUBNET_IDS[$i]})"
    break
  fi
done
done
echo ""
echo "The 'private.iam.cloud.ibm.com' DNS name in this VPC will now resolve to the"
echo "Reserved IP addresses above. Monitor your environment for any connectivity"
echo "issues and review the documentation for resolution steps if needed."

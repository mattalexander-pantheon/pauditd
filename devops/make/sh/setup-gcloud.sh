#! /bin/bash
#  upgrade CircleCI builtin gcloud tools, and set it up
#
# The following ENV vars must be set before calling this script:
#
#   GCLOUD_EMAIL           # user-id for circle to authenticate to google cloud
#   GCLOUD_KEY             # base64 encoded key
#   CLUSTER_ID             # (DEPRECATED) this will set the cluster to connect to (when not used it connects to all of them)
#   CLUSTER_DEFAULT        # sets default cluster (if using CLUSTER_ID then this is set to the specified cluster)

set -eou pipefail
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

CLUSTER_DEFAULT=${CLUSTER_DEFAULT:-"cluster-01"}
ALL_CLUSTERS=("cluster-01" "cluster-02" "cluster-03" "cluster-05" "cluster-06" "cluster-07" "cluster-08" "cluster-09" \
                           "control-01" \
                           "sandbox-01" "sandbox-02" "sandbox-03" "sandbox-04")

CLUSTER_ID=${CLUSTER_ID:-}
GCLOUD_EMAIL=${GCLOUD_EMAIL:-}
GCLOUD_KEY=${GCLOUD_KEY:-}

if [[ -n "$CLUSTER_ID" ]] ; then
  ALL_CLUSTERS=("$CLUSTER_ID")
	CLUSTER_DEFAULT="$CLUSTER_ID"
fi

echo "Requested Clusters: ${ALL_CLUSTERS[*]}"
echo "Default Cluster: $CLUSTER_DEFAULT"

if [[ -z "$GCLOUD_EMAIL" ]]; then
  echo "GCLOUD_EMAIL is required"
  exit 1
fi

if [[ -z "$GCLOUD_KEY" ]]; then
  echo "GCLOUD_KEY is required"
  exit 1
fi

gcloud=$(command -v gcloud)
kubectl=$(command -v kubectl)

echo "$GCLOUD_KEY" | base64 --decode > gcloud.json
$gcloud auth activate-service-account "$GCLOUD_EMAIL" --key-file gcloud.json

sshkey="$HOME/.ssh/google_compute_engine"
if [[ ! -f "$sshkey" ]] ; then
  ssh-keygen -f "$sshkey" -N ""
fi

for cluster in "${ALL_CLUSTERS[@]}"; do
  cmd="${SCRIPTPATH}/cluster-vars.sh $cluster"
  # set the $CLUSTER_* variables used below.
  eval "$($cmd)"

  if [[ "$CLUSTER_DEFAULT" == "$cluster" ]] ; then
    DEFAULT_CLUSTER_PROJECT=$CLUSTER_PROJECT
    DEFAULT_CLUSTER_ZONE=$CLUSTER_ZONE
    DEFAULT_CLUSTER_LONG_NAME=$CLUSTER_LONG_NAME
  fi

	echo "Getting Credentials for cluster: $CLUSTER_ID zone: $CLUSTER_ZONE project: $CLUSTER_PROJECT"
  $gcloud container clusters get-credentials "${CLUSTER_ID}" --project="${CLUSTER_PROJECT}" --zone="${CLUSTER_ZONE}" > /dev/null
done

echo "Setting Primary Project"
$gcloud config set project "$DEFAULT_CLUSTER_PROJECT"

echo "Setting Primary Zone"
$gcloud config set compute/zone "$DEFAULT_CLUSTER_ZONE"

echo "Setting Primary Cluster"
$gcloud config set container/cluster "$CLUSTER_DEFAULT"
$kubectl config use-context "$DEFAULT_CLUSTER_LONG_NAME"

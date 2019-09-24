#!/bin/bash

set -eou pipefail

# clusters should always be pulled

CLUSTER_DEFAULT=cluster-02 sh/setup-gcloud.sh

default_context=$(kubectl config current-context)
if [[ "$default_context" != "gke_pantheon-internal_us-central1-a_cluster-02" ]] ; then
  echo "Default context was not set correctlyfor kubectl, expected gke_pantheon-internal_us-central1-a_cluster-02 got $default_context"
  exit 1
fi

gcloud_default_context=$(gcloud config get-value container/cluster)
if [[ "$gcloud_default_context" != "cluster-02" ]] ; then
  echo "Default context was not set correctly for gcloud, expected gke_pantheon-internal_us-central1-a_cluster-02 got $gcloud_default_context"
  exit 1
fi

exit 0

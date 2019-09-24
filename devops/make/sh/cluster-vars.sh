#!/bin/bash

function cluster_vars {
    case "$1" in
        control-01)
            CLUSTER_PROJECT="pantheon-dmz"
            CLUSTER_ID="control-01"
            CLUSTER_ZONE="us-central1"
            ;;
        cluster-01)
            CLUSTER_PROJECT="pantheon-internal"
            CLUSTER_ID="cluster-01"
            CLUSTER_ZONE="us-central1-b"
            ;;
        cluster-02)
            CLUSTER_PROJECT="pantheon-internal"
            CLUSTER_ID="cluster-02"
            CLUSTER_ZONE="us-central1-a"
            ;;
        cluster-03)
            CLUSTER_PROJECT="pantheon-internal"
            CLUSTER_ID="cluster-03"
            CLUSTER_ZONE="europe-west4"
            ;;
        cluster-05)
            CLUSTER_PROJECT="pantheon-internal"
            CLUSTER_ID="cluster-05"
            CLUSTER_ZONE="europe-west4"
            ;;
        cluster-06)
            CLUSTER_PROJECT="pantheon-internal"
            CLUSTER_ID="cluster-06"
            CLUSTER_ZONE="australia-southeast1"
            ;;
        cluster-07)
            CLUSTER_PROJECT="pantheon-internal"
            CLUSTER_ID="cluster-07"
            CLUSTER_ZONE="australia-southeast1"
            ;;
        cluster-08)
            CLUSTER_PROJECT="pantheon-internal"
            CLUSTER_ID="cluster-08"
            CLUSTER_ZONE="northamerica-northeast1"
            ;;
        cluster-09)
            CLUSTER_PROJECT="pantheon-internal"
            CLUSTER_ID="cluster-09"
            CLUSTER_ZONE="northamerica-northeast1"
            ;;
        sandbox-01)
            CLUSTER_PROJECT="pantheon-sandbox"
            CLUSTER_ID="sandbox-01"
            CLUSTER_ZONE="us-central1"
            ;;
        sandbox-02)
            CLUSTER_PROJECT="pantheon-sandbox"
            CLUSTER_ID="sandbox-02"
            CLUSTER_ZONE="us-east4"
            ;;
        sandbox-03)
            CLUSTER_PROJECT="pantheon-sandbox"
            CLUSTER_ID="sandbox-03"
            CLUSTER_ZONE="us-west1"
            ;;
        sandbox-04)
            CLUSTER_PROJECT="pantheon-sandbox"
            CLUSTER_ID="sandbox-04"
            CLUSTER_ZONE="us-west2"
            ;;
        *)
            echo "Unknown cluster $CLUSTER_ID"
            exit 1
            ;;
    esac
    CLUSTER_LONG_NAME="gke_${CLUSTER_PROJECT}_${CLUSTER_ZONE}_${CLUSTER_ID}"
    cat <<-EOF
    CLUSTER_PROJECT=$CLUSTER_PROJECT
    CLUSTER_ID=$CLUSTER_ID
    CLUSTER_LONG_NAME=$CLUSTER_LONG_NAME
    CLUSTER_ZONE=$CLUSTER_ZONE
EOF
}

cluster_vars "$@"

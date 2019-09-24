#! /bin/bash

set -eu -o pipefail

function log() {
    echo "(build-docker)" "$@"
}

function build() {
    local image
    image=$1
    log "building docker image $image"
    docker build --pull -t "$image" .
}

IMAGE="$1"
if [[ -z $IMAGE ]]; then
    echo "Usage: $0 IMAGE"
    exit 1
fi
FORCE_BUILD=${FORCE_BUILD:-false}
TRY_PULL=${TRY_PULL:-false}
if [[ $FORCE_BUILD == true ]]; then
    log "forcing docker build, not checking existence"
    build "$IMAGE"
    exit
fi
if [[ $(docker images -q "$IMAGE" | wc -l) -gt 0 ]]; then
    log "found $IMAGE locally, not building"
    exit
fi
if [[ $TRY_PULL == true ]]; then
    log "attempting to pull docker image $IMAGE"
    docker pull "$IMAGE" &>/dev/null && exit;
    log "unable to pull image, proceeding to build"
fi
build "$IMAGE"

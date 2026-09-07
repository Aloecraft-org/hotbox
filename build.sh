#!/usr/bin/env bash
# Build every hotbox image and push it to the local registry.
#
# Entry point: ./build.sh, no arguments.
# Configurable:  ENGINE (podman or docker), PULL, REGISTRY, IMAGES_YAML,
#                BUILD_DIR.
# Fan-out:       config/images.yaml, rendered by generate.py into one build
#                context per image; ENGINE picks the flag set.

set -euo pipefail

ENGINE=${ENGINE:-podman}
PULL=${PULL:-always}
REGISTRY=localhost:5000
IMAGES_YAML=config/images.yaml
BUILD_DIR=build

# podman takes a pull policy and needs to be told the registry is plain HTTP;
# docker's --pull is a boolean and localhost is insecure by default.
# PULL=always re-checks the base on every build, which is what the weekly
# timer wants and what makes a hand-run fail when the registry is unreachable
# or rate limiting. PULL=missing uses the local base if there is one.
case "$ENGINE" in
  podman) BUILD_FLAGS=(--pull="$PULL"); PUSH_FLAGS=(--tls-verify=false) ;;
  docker)
    # docker's --pull is a boolean, so it is on for always and off otherwise.
    if [ "$PULL" = always ]; then BUILD_FLAGS=(--pull); else BUILD_FLAGS=(); fi
    PUSH_FLAGS=()
    ;;
  *) echo "unsupported ENGINE: $ENGINE" >&2; exit 1 ;;
esac

# generate.py prints one image name per line, in the order images.yaml lists them.
mapfile -t NAMES < <(./generate.py "$IMAGES_YAML" "$BUILD_DIR")

for name in "${NAMES[@]}"; do
  context="$BUILD_DIR/$name"
  tag="$REGISTRY/hotbox/$name:latest"
  # -f is explicit: podman finds Containerfile on its own, docker only looks
  # for Dockerfile.
  "$ENGINE" build "${BUILD_FLAGS[@]}" -f "$context/Containerfile" -t "$tag" "$context"
  "$ENGINE" push "${PUSH_FLAGS[@]}" "$tag"
  echo "built and pushed $tag"
done

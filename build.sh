#!/usr/bin/env bash
# Build every hotbox image and push it to the local registry.
#
# Entry point: ./build.sh, no arguments.
# Configurable:  ENGINE (podman or docker), REGISTRY, IMAGES_YAML, BUILD_DIR.
# Fan-out:       config/images.yaml, rendered by generate.py into one build
#                context per image; ENGINE picks the flag set.

set -euo pipefail

ENGINE=${ENGINE:-podman}
REGISTRY=localhost:5000
IMAGES_YAML=config/images.yaml
BUILD_DIR=build

# podman takes a pull policy and needs to be told the registry is plain HTTP;
# docker's --pull is a boolean and localhost is insecure by default.
case "$ENGINE" in
  podman) BUILD_FLAGS=(--pull=always); PUSH_FLAGS=(--tls-verify=false) ;;
  docker) BUILD_FLAGS=(--pull);        PUSH_FLAGS=() ;;
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

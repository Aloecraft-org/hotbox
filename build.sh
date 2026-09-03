#!/usr/bin/env bash
# Build every hotbox image and push it to the local registry.
#
# Entry point: ./build.sh, no arguments.
# Configurable:  ENGINE (podman or docker), REGISTRY, IMAGES.
# Fan-out:       IMAGES, one build+push per row; ENGINE picks the flag set.

set -euo pipefail

ENGINE=${ENGINE:-podman}
REGISTRY=localhost:5000

# name and BASE, one image per row.
IMAGES=(
  "debian debian:bookworm-slim"
  "alpine alpine:3"
  "ubuntu ubuntu:24.04"
)

# podman takes a pull policy and needs to be told the registry is plain HTTP;
# docker's --pull is a boolean and localhost is insecure by default.
case "$ENGINE" in
  podman) BUILD_FLAGS=(--pull=always); PUSH_FLAGS=(--tls-verify=false) ;;
  docker) BUILD_FLAGS=(--pull);        PUSH_FLAGS=() ;;
  *) echo "unsupported ENGINE: $ENGINE" >&2; exit 1 ;;
esac

for row in "${IMAGES[@]}"; do
  read -r name base <<<"$row"
  tag="$REGISTRY/hotbox/$name:latest"
  "$ENGINE" build "${BUILD_FLAGS[@]}" --build-arg "BASE=$base" -t "$tag" .
  "$ENGINE" push "${PUSH_FLAGS[@]}" "$tag"
  echo "built and pushed $tag from $base"
done

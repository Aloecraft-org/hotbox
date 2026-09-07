# NOT the build input any more. build.sh renders a Containerfile per\n# image from config/images.yaml via generate.py. This file survives only\n# as the fedora recipe, which images.yaml lists under images_other and\n# does not build. Delete it once fedora is dropped or given a real entry.\n\n# Base image plus the obvious tools. ARG BASE selects the base; the package
# manager is detected from /etc/os-release so every base gets the same list.
# The tool list is the only thing here worth editing.

ARG BASE=docker.io/library/debian:bookworm-slim
FROM ${BASE}
RUN set -eu; . /etc/os-release; case "$ID" in \
      debian|ubuntu) apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget jq git less procps iproute2 iputils-ping dnsutils vim-tiny \
        && rm -rf /var/lib/apt/lists/* ;; \
      alpine) apk add --no-cache ca-certificates curl wget jq git less procps iproute2 iputils-ping bind-tools vim ;; \
      fedora) dnf install -y ca-certificates curl wget jq git less procps-ng iproute iputils bind-utils vim-minimal \
        && dnf clean all ;; \
      *) echo "unsupported base: $ID" >&2; exit 1 ;; \
    esac
WORKDIR /work
CMD ["/bin/sh"]

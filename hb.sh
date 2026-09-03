# Shell function: hb [name] [command...]
# Entry point: hb. Image name defaults to debian; HB_ENGINE picks the engine.

hb() {
  local name="${1:-debian}"; shift || true
  local eng="${HB_ENGINE:-podman}"
  "$eng" run --rm -it -v "$PWD":/work -w /work \
    "localhost:5000/hotbox/${name}:latest" "$@"
}

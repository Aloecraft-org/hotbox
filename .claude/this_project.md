# This project

<!-- Per repo. This is the only file that changes between repos.
     human-surfaces.md defines the grades; this file assigns them. -->

Spec: @../README.md

## What this is

hotbox: daily-rebuilt convenience container images pushed to a local
registry shared by podman and docker. Four small files plus systemd
units. Dev convenience only; never a `FROM` base for real projects.

## Surfaces

| path | grade |
|------|-------|
| `*`  | tool  |

The human reads, runs, and hand-edits every file in this repo. There is
no maintainer-grade code here; if a file needs a depth section, the tool
has grown past its spec, which is a problem to raise, not to manage.

## Project notes

- The spec's inline snippets (Containerfile, hb.sh) are the intended
  final shape. Deviate only to fix an error, and say you did.
- `--tls-verify=false` is a podman flag; docker push does not accept it.
  build.sh adds it only when the engine is podman.
- Acceptance list in the spec is exhaustive. No other tests.
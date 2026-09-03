# hotbox

Base images plus the obvious tools (curl, wget, jq, git, less, procps,
iproute2, dns tools, vim), rebuilt weekly and pushed to a local registry that
both podman and docker can pull from.

Dev convenience only. Never use these as a `FROM` base in a real project.

| image                                   | base                 |
|-----------------------------------------|----------------------|
| `localhost:5000/hotbox/debian:latest`   | debian:bookworm-slim |
| `localhost:5000/hotbox/alpine:latest`   | alpine:3             |
| `localhost:5000/hotbox/ubuntu:latest`   | ubuntu:24.04         |

## Install

Assumes the repo is at `~/hotbox`; if not, edit the two paths in
`systemd/hotbox-build.service`.

1. **Registry.**

   ```sh
   mkdir -p ~/.local/share/hotbox/registry ~/.config/containers/systemd
   cp systemd/hotbox-registry.container ~/.config/containers/systemd/
   systemctl --user daemon-reload && systemctl --user start hotbox-registry
   ```

   Create the data directory first. Podman does not create it, and the
   service exits 125 with `statfs ...: no such file or directory`.

   Run `loginctl enable-linger $USER` if it should stay up without an
   active login session.

2. **Podman config.** Merge `config/registries.conf.snippet` into
   `~/.config/containers/registries.conf`. Docker needs nothing: it treats
   localhost registries as insecure already.

3. **Timer.**

   ```sh
   mkdir -p ~/.config/systemd/user
   cp systemd/hotbox-build.{service,timer} ~/.config/systemd/user/
   systemctl --user daemon-reload && systemctl --user enable --now hotbox-build.timer
   ```

   Check it with `systemctl --user list-timers`.

4. **Shell function.** Add `source ~/hotbox/hb.sh` to `.bashrc` or `.zshrc`.

Build by hand any time with `./build.sh`, or `ENGINE=docker ./build.sh`.

## Use

```sh
hb                            # debian shell in the current directory
hb alpine
hb ubuntu curl -I example.com
HB_ENGINE=docker hb           # same image, docker instead of podman
```

## The cross-engine rule

Always use the full `localhost:5000/hotbox/<name>:latest` tag, for builds,
pushes and runs. The registry is the only thing podman and docker share; a
bare `hotbox/<name>` tag lands in one engine's local store and is invisible
to the other.

If an unprefixed image does show up in docker and you want it in podman:

```sh
podman pull docker-daemon:hotbox/debian:latest          # read docker's store
docker save hotbox/debian:latest | podman load           # pipe it across
docker tag hotbox/debian:latest localhost:5000/hotbox/debian:latest \
  && docker push localhost:5000/hotbox/debian:latest     # or just retag and push
```

The third one is usually what you want; after it, both engines pull the same
image the normal way.

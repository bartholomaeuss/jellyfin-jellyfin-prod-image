# Jellyfin Production Image

This repository packages a reproducible Docker wrapper around the official
[Jellyfin](https://jellyfin.org/) image plus a small set of helper scripts that
make it easy to stand up a media server on a remote host with predictable
storage, mount, and restart defaults. The scripts are geared toward **fast host
validation, lab experiments, and repeatable deployments** when you want Jellyfin
online quickly and consistently.

> **Warning**  
> The automation here is **not** a full production hardening guide. It favors
> speed and convenience over exhaustive security controls. For mission-critical
> use, fork the Dockerfile and scripts, add your own hardening, secrets
> management, and CI/CD pipeline.

## Why this repo?

- **Remote bootstrap** - `provide_container.sh` ships the Dockerfile to the host,
  builds the image in place, and runs Jellyfin with the right mounts and restart
  policy.
- **Predictable storage** - the container assumes `/media` as the working
  directory so NAS or SMB mounts are immediately visible.
- **Host prep helpers** - `scripts/docker/prerun.sh` installs CIFS tooling,
  creates the Jellyfin directory layout, and mounts the network share.
- **Repeatable defaults** - aligns with a homelab workflow where clean, reliable
  deployment beats long-running infrastructure drift.

## Requirements

- Workstation with `bash`, `ssh`, and `scp`.
- Remote host with Docker Engine, sudo access, and network reachability to your
  NAS or SMB share.
- A valid CIFS path (for example `//nas01/media`) and credentials or guest
  access as required.
- Optional: Debian/Ubuntu-based remote host to use the helper scripts as-is
  (they rely on `apt-get`).

## Repository layout

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Minimal wrapper that pins to upstream Jellyfin and sets `/media` as the working directory. |
| `provide_container.sh` | Main automation script; uploads, builds, and runs the image remotely. |
| `scripts/docker/prerun.sh` | Idempotent host prep (packages, directories, CIFS mount). |
| `scripts/docker/run.sh` | Reserved for future orchestration (empty). |
| `scripts/docker/postrun.sh` | Reserved for future orchestration (empty). |

## Quick start

```bash
git clone https://github.com/<you>/jellyfin-jellyfin-prod-image.git
cd jellyfin-jellyfin-prod-image

export storage='//nas01/media'
export PRERUN_USER='jellyfin'
./scripts/docker/prerun.sh

./provide_container.sh \
  -d Dockerfile \
  -i jellyfin-prod \
  -t 2025.12 \
  -r media.example.com \
  -u jellyfin \
  -s //nas01/media
```

The flow above will:

1. Install CIFS tooling on the remote host (if missing).
2. Create `~/jellyfin/{media,config,cache}` for the specified user.
3. Mount the NAS share at `~/jellyfin/media`.
4. Upload the Dockerfile, rebuild the image, and launch the container with host
   networking and persistent volumes.

## `provide_container.sh` reference

The deploy script is intentionally small but focused:

- Adds the NAS share to `/etc/fstab` on the remote host.
- Uploads the Dockerfile and rebuilds the image on the host.
- Ensures `~/jellyfin/{config,cache,media}` exist with the right ownership.
- Stops any previous containers for the same image and starts a clean one.

| Flag | Required | Purpose |
| --- | --- | --- |
| `-d <dockerfile>` | No (defaults to `Dockerfile`) | Dockerfile to upload/build remotely. |
| `-i <image>` | **Yes** | Docker image name to tag and run. |
| `-t <tag>` | **Yes** | Version tag (for example `2025.12`). |
| `-r <host>` | **Yes** | SSH hostname or IP of the remote Docker host. |
| `-u <user>` | **Yes** | Remote UNIX user that owns the Jellyfin directories. |
| `-s <//server/share>` | **Yes** | CIFS path that should be mounted at `/media`. |

Tip: export these values as environment variables or wrap the command in a
helper script so you do not have to type them repeatedly.

## Host preparation notes

- `scripts/docker/prerun.sh` accepts the following environment variables:
  - `storage`/`STORAGE`: required CIFS path.
  - `PRERUN_USER`: remote user (defaults to `$USER`).
  - `MEDIA_DIR`: override mount target (defaults to `~/jellyfin/media`).
  - `PRERUN_PACKAGES`: custom package list (space-delimited).
- The script is safe to re-run; it only appends the `fstab` entry if missing and
  remounts afterward.
- If you only need the CIFS tooling and prefer to manage mounts manually, run:
  ```bash
  sudo apt-get -y install samba cifs-utils keyutils iftop
  ```

## Troubleshooting

- **Mount fails** - confirm the NAS is reachable from the remote host and the
  CIFS credentials are valid; re-run `prerun.sh` after fixing.
- **Container restarts immediately** - check `docker logs <container>`; Jellyfin
  may be waiting on the media mount or a corrupted config directory.
- **Permission issues** - ensure the NAS export allows the remote user and that
  `~/jellyfin` is owned by the same account specified via `-u`.

## Further reading

- [Jellyfin documentation](https://jellyfin.org/docs/)
- [Jellyfin Docker hub](https://hub.docker.com/r/jellyfin/jellyfin)

## License

Distributed under the terms of the [LICENSE](LICENSE) file.

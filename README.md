# Jellyfin Production Image

Purpose-built automation for building and running a hardened
[Jellyfin](https://jellyfin.org/) media server container on a remote host. The
repository wraps the official `jellyfin/jellyfin:latest` image with conventions
for persistent storage, NAS mounting, and one-command deployment.

## Highlights
- **Production-aligned image** – Dockerfile pins to upstream Jellyfin and
  assumes `/media` as the working directory so the container can immediately see
  attached network storage.
- **Remote bootstrap** – `provide_container.sh` uploads the Dockerfile, builds
  the image on the remote host, and ensures the container runs with the correct
  volume bindings and restart policy.
- **Host preparation helpers** – `scripts/docker/prerun.sh` installs required
  packages, creates Jellyfin directories, and mounts the network share before
  any container work begins.

## Requirements
- Workstation with `bash`, `ssh`, and `scp`.
- Remote host with Docker Engine, passwordless or password-based sudo access,
  and outbound connectivity to your NAS or SMB share.
- Credentials or guest access to the network share you want Jellyfin to read
  (`//server/share` style path).
- Optional: Debian/Ubuntu-based host to use the helper scripts as-is (they rely
  on `apt-get`).

## Repository Tour
| Path | Description |
| --- | --- |
| `Dockerfile` | Minimal wrapper that ensures `/media` is the working directory. |
| `provide_container.sh` | Main automation script; builds/runs the container remotely. |
| `scripts/docker/prerun.sh` | Idempotent host prep (packages, directory creation, CIFS mount). |
| `scripts/docker/run.sh`, `postrun.sh` | Hooks reserved for future orchestration steps. |

## Quick Start
1. **Clone and inspect**
   ```bash
   git clone https://github.com/<you>/jellyfin-jellyfin-prod-image.git
   cd jellyfin-jellyfin-prod-image
   ```
2. **Prepare the remote host (optional but recommended)**
   ```bash
   export storage='//nas01/media'
   export PRERUN_USER='jellyfin'
   ./scripts/docker/prerun.sh
   ```
   This installs CIFS tooling, creates `~/jellyfin/{media,config,cache}`, adds
   the NAS entry to `/etc/fstab`, and mounts it.
3. **Deploy Jellyfin**
   ```bash
   ./provide_container.sh \
     -d Dockerfile \
     -i jellyfin-prod \
     -t 2025.12 \
     -r media.example.com \
     -u jellyfin \
     -s //nas01/media
   ```

## `provide_container.sh` Reference
The deploy script is intentionally small but powerful:
- Adds the NAS share to `/etc/fstab` on the remote host.
- Uploads the Dockerfile and rebuilds the image in-place.
- Ensures `~/jellyfin/{config,cache,media}` exist with the correct permissions.
- Stops any running containers built from the previous tag and launches the new
  one with host networking plus persistent volumes.

| Flag | Required | Purpose |
| --- | --- | --- |
| `-d <dockerfile>` | No (defaults to `Dockerfile`) | Dockerfile to upload/build remotely. |
| `-i <image>` | **Yes** | Docker image name to tag and run. |
| `-t <tag>` | **Yes** | Version tag (e.g., `2025.12`). |
| `-r <host>` | **Yes** | SSH hostname or IP of the remote Docker host. |
| `-u <user>` | **Yes** | Remote UNIX user that owns the Jellyfin directories. |
| `-s <//server/share>` | **Yes** | CIFS path that should be mounted at `/media`. |

> Tip: export these values as environment variables or store them in a helper
> script so you do not have to type them repeatedly.

## Host Preparation Notes
- `scripts/docker/prerun.sh` accepts the following environment variables:
  - `storage`/`STORAGE`: required CIFS path.
  - `PRERUN_USER`: remote user (defaults to `$USER`).
  - `MEDIA_DIR`: override mount target (defaults to `~/jellyfin/media`).
  - `PRERUN_PACKAGES`: custom package list (space-delimited).
- The script is idempotent and safe to run multiple times; it only appends the
  `fstab` entry if missing and mounts afterwards.
- `scripts/docker/run.sh` and `postrun.sh` are empty placeholders you can hook
  into CI/CD tooling (e.g., to notify monitoring or run smoke tests after
  deployment).
- Here is a minimal helper that simply installs the packages
  Jellyfin relies on for CIFS access. Run it when you only need the tooling and
  plan to configure mounts manually:
  ```bash
  sudo apt-get -y install samba cifs-utils keyutils iftop
  ```

## Troubleshooting
- **Mount fails** – verify the NAS is reachable from the remote host and the
  CIFS credentials (or guest access) are valid; re-run `prerun.sh` after fixing.
- **Container restarts immediately** – inspect logs via
  `docker logs <container>`; Jellyfin may be waiting on the media mount or a
  corrupted config directory.
- **Permission issues** – ensure the NAS export allows the remote user and that
  `~/jellyfin` is owned by the same account specified via `-u`.

## License
Distributed under the terms of the [LICENSE](LICENSE) file.

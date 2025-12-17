#!/usr/bin/env bash
set -euo pipefail

# Pre-run helper for the host that will execute the Jellyfin container.
# Ensures required packages exist, directories are prepared, and storage is
# mounted before the container is started.
# NOTE: Production deployments rely on Ansible; this script is only meant for
# quick manual verification on a test host.

storage="${storage:-${STORAGE:-}}"
if [ -z "${storage}" ]; then
  echo "Missing storage path. Export env var 'storage' (or 'STORAGE')." >&2
  exit 1
fi

target_user="${target_user:-${PRERUN_USER:-${USER:-$(id -un)}}}"
home_dir=$(eval echo "~${target_user}")
if [ ! -d "${home_dir}" ]; then
  echo "Home directory for '${target_user}' not found." >&2
  exit 1
fi

media_dir="${media_dir:-${MEDIA_DIR:-"${home_dir}/jellyfin/media"}}"
config_dir="${home_dir}/jellyfin/config"
cache_dir="${home_dir}/jellyfin/cache"

packages_default=(samba cifs-utils keyutils iftop)
if [ -n "${PRERUN_PACKAGES:-}" ]; then
  # shellcheck disable=SC2206
  packages=(${PRERUN_PACKAGES})
else
  packages=("${packages_default[@]}")
fi

sudo apt-get update -y
if [ ${#packages[@]} -gt 0 ]; then
  sudo apt-get install -y "${packages[@]}"
fi

sudo mkdir -p "${media_dir}" "${config_dir}" "${cache_dir}"
sudo chown -R "${target_user}:${target_user}" "${home_dir}/jellyfin"

fstab_entry="${storage}  ${media_dir}  cifs  guest,x-systemd.automount  0  0"
if ! grep -qsF "${fstab_entry}" /etc/fstab; then
  echo "${fstab_entry}" | sudo tee -a /etc/fstab >/dev/null
fi

sudo mount -a

cat <<EOM
Mounted ${storage} at ${media_dir}
Jellyfin directories ready in ${home_dir}/jellyfin
EOM

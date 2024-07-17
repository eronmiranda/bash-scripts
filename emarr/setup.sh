#!/bin/bash

set -euo pipefail

ME=$(basename "$0")

log() {
  >&2 echo "${ME}: $*"
}

die() {
  log "$@"
  exit 1
}

OS="$(uname)"
[[ "$OS" != "Linux" ]] && die  "Unsupported operating system ${OS}"

apt-get -q update

log "installing jq..."
apt-get -q -y install jq

log "installing git..."
apt-get -q -y install git
apt-get -q -y install wireguard wireguard-tools
apt-get -q -y install samba

# Function to check if a package exists
package_exists() {
  dpkg -l | grep -w "$1" &> /dev/null
}

# List of packages to remove
OLD_DOCKER_PACKAGES=("docker.io" "docker-doc" "docker-compose" "docker-compose-v2" "podman-docker" "containerd" "runc")

log "Removing old docker packages..."
for pkg in "${OLD_DOCKER_PACKAGES[@]}"; do
  if package_exists "$pkg"; then
    apt-get -q remove "$pkg"
  fi
done

# install Docker
apt-get -q -y install ca-certificates curl
apt-get -q -y upgrade
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" -o "/etc/apt/keyrings/docker.asc"
chmod a+r "/etc/apt/keyrings/docker.asc"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. "/etc/os-release" && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
log "installing docker..."
apt-get -q -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# docker post-installation
usermod -aG docker "$USER"

# ufw firewall config
log "setting up essential ufw firewall config..."
ufw allow 47111/udp # wireguard
ufw allow 22/tcp # ssh
ufw allow Samba
ufw route allow in on wg0
ufw enable
ufw status

#!/bin/bash
# shellcheck disable=SC2312

if [[ -z "${DOTFILES_ROOT}" ]]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    elif command -v dirname >/dev/null 2>&1; then
        DOTFILES_ROOT="$(cd "$(dirname "$0")" || return; pwd)"
	else
        echo >&2 '[Error] cannot determine root (try running from working directory)'
        exit 1
    fi
fi


# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

# Always assume trillian is running debian
load_debian_common

USERS=(
    "media:Media files and folders:994:/sbin/nologin:/srv/media:media"
    "matt:Matt Day:1000:/bin/zsh:/home/matt:media,backups,sudo,docker"
    "nicky:Nicola Purves:1001:/bin/bash:/home/nicky:media,backups"
    "plex:Plex Media Server:997:/sbin/nologin:/opt/containerised-apps/plex/config:media"
    "sonarr:Sonarr:996:/sbin/nologin:/opt/containerised-apps/sonarr/config:media"
    "bazarr:Bonarr:982:/sbin/nologin:/opt/containerised-apps/bazarr/config:media"
    "radarr:Ronarr:981:/sbin/nologin:/opt/containerised-apps/ronarr/config:media"
    "nzbget:NZBGet:995:/sbin/nologin:/opt/containerised-apps/nzbget/config:media"
    "transmission:Transmission:993:/sbin/nologin:/opt/containerised-apps/transmission/config:media"
    "unifi:Unifi Controller:992:/sbin/nologin:/opt/containerised-apps/unifi/config:unifi"
    "traffic-gen:Traffic Generator:991:/sbin/nologin:/opt/containerised-apps/traffic-gen:traffic-gen"
    "openvpn:OpenVPN Access Server:990:/sbin/nologin:/opt/containerised-apps/openvpn:openvpn"
    "prometheus:Prometheus:989:/sbin/nologin:/opt/containerised-apps/prometheus/config:monitoring"
    "grafana:Grafana:988:/sbin/nologin:/opt/containerised-apps/grafana/config:monitoring"
    "unifi-poller:Unifi Poller:987:/sbin/nologin:/opt/containerised-apps/unifi-poller/config:monitoring"
    "samba:Samba Service:986:/sbin/nologin:/opt/containerised-apps/samba/config:backups,media"
    "gitlab:GitLab:985:/sbin/nologin:/opt/containerised-apps/gitlab/config:gitlab"
    "nginx:Nginx:984:/sbin/nologin:/opt/containerised-apps/nginx/config:nginx"
    "pi-hole:Pi Hole:983:/sbin/nologin:/opt/containerised-apps/pi-hole/config:pi-hole"
    "weechat:Weechat:980:/sbin/nologin:/opt/containerised-apps/weechat/config:weechat"
    "harmony:Harmony API:979:/sbin/nologin:/opt/containerised-apps/harmony-api/config:harmony"
    "wireguard:Wireguard VPN:978:/sbin/nologin:/opt/containerised-apps/wireguard/config:wireguard"
)

APT_PACKAGES=(apt-transport-https ca-certificates curl gnupg avahi-daemon avahi-utils ethtool build-essential cmake lm-sensors)

add_group() {
    if ! getent group "$1" >/dev/null 2>&1; then
        info Adding group "$1" with GID "$2"
        groupadd -g "$2" "$1"
    fi
}

users() {
    # Create docker and backups groups
    add_group docker 998
    add_group backups 901
    add_group monitoring 902
    # Loop through users and create/update them
    for user in "${USERS[@]}"; do
        name="$(echo "${user}" | cut -d : -f 1)"
        fullname="$(echo "${user}" | cut -d : -f 2)"
        uid="$(echo "${user}" | cut -d : -f 3)"
        shell="$(echo "${user}" | cut -d : -f 4)"
        home="$(echo "${user}" | cut -d : -f 5)"
        groups="$(echo "${user}" | cut -d : -f 6)"
        if getent group "${name}" >/dev/null 2>&1; then
            sudo groupmod -g "${uid}" "${name}"
        else
            info Creating group "${name}"
            sudo groupadd -g "${uid}" "${name}"
        fi
        if id -u "${name}" >/dev/null 2>&1; then
            sudo usermod -c "${fullname}" -u "${uid}" -g "${uid}" -d "${home}" -aG "${groups}" -s "${shell}" "${name}"
        else
            info Creating user "${name}"
            sudo useradd -c "${fullname}" -M -u "${uid}" -g "${uid}" -d "${home}" -G "${groups}" -s "${shell}" "${name}"
        fi
    done
}

install_docker() {
    if [[ -f "${OS_BOOTSTRAP_ROOT}/docker.sh" ]]; then
        "${OS_BOOTSTRAP_ROOT}/docker.sh"
    fi
    # Set up Docker IPv6 support
    if [[ ! -f /etc/docker/daemon.json ]]; then
        if [[ ! -d /etc/docker ]]; then
            mkdir /etc/docker
        fi
        cat <<'EOF' | sudo tee /etc/docker/daemon.json >/dev/null
{
  "ipv6": true,
  "fixed-cidr-v6": "fd00::/80",
  "experimental": true, 
  "ip6tables": true
}
EOF
        # Restart Docker
        systemctl restart docker
        info Sleeping 30 seconds to allow Docker Daemon to start
        sleep 30
    fi
}

install_docker_compose() {
    # Get latest compose version
    CURRENT_VERSION="$(curl --silent https://api.github.com/repos/docker/compose/releases | jq -r '[.[] | select(.prerelease == false)][0].tag_name')"
    BACKUP_VERSION=1.29.2
    if [[ "${CURRENT_VERSION}" = null ]]; then
        CURRENT_VERSION="${BACKUP_VERSION}"
    fi
    UPGRADE=1
    if [[ -x /usr/local/bin/docker-compose ]]; then
        INSTALLED_VERSION="$(docker-compose --version | cut -f 3 -d ' ' | cut -f 1 -d ,)"
        COMPARE_INSTALLED="${INSTALLED_VERSION//\./}"
        COMPARE_CURRENT="${CURRENT_VERSION//\./}"
        if [[ "${COMPARE_INSTALLED}" -lt "${COMPARE_CURRENT}" ]]; then
            info "Updating Docker Compose (from ${INSTALLED_VERSION} to ${CURRENT_VERSION})"
        else
            info "Docker compose up to date (version ${CURRENT_VERSION})"
            UPGRADE=0
        fi
    fi
    if [[ "${UPGRADE}" = 1 ]]; then
        sudo curl -L "https://github.com/docker/compose/releases/download/${CURRENT_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    fi

}

# Set up HPE bundled software
hpe() {
    if [[ ! -f /usr/share/keyrings/hpe-mcp-archive-keyring.gpg ]]; then
        curl -fsSL https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key1.pub | sudo gpg --dearmor -o /usr/share/keyrings/hpe-mcp-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hpe-mcp-archive-keyring.gpg] http://downloads.linux.hpe.com/SDR/repo/mcp stable/current non-free" | sudo tee /etc/apt/sources.list.d/hpe-mcp.list >/dev/null
        DEBIAN_FRONTEND="noninteractive" sudo apt-get update
    fi
    APT_PACKAGES=(amsd)
    install_apt_packages
}

sensors() {
    if ! grep coretemp /etc/modules >/dev/null 2>&1; then
        info "Setting up sensors"
        echo coretemp | sudo tee -a /etc/modules >/dev/null 2>&1
    fi
}

main() {
    users
    install_apt_packages
    install_docker
    install_docker_compose
    hpe
    sensors
}

main

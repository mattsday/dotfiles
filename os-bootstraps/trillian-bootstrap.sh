#!/bin/bash
USERS=(
    "matt:Matt Day:1000:/bin/zsh:/home/matt:media,backups,sudo,docker"
    "nicky:Nicola Purves:1001:/bin/bash:/home/nicky:media,backups"
    "plex:Plex Media Server:997:/sbin/nologin:/opt/containerised-apps/plex/config:media"
    "sonarr:Sonarr:996:/sbin/nologin:/opt/containerised-apps/sonarr/config:media"
    "nzbget:NZBGet:995:/sbin/nologin:/opt/containerised-apps/nzbget/config:media"
    "media:Media files and folders:994:/sbin/nologin:/srv/media:media"
    "transmission:Transmission:993:/sbin/nologin:/opt/containerised-apps/transmission/config:media"
    "unifi:Unifi Controller:992:/sbin/nologin:/opt/containerised-apps/unifi/config:unifi"
    "traffic-gen:Traffic Generator:991:/sbin/nologin:/opt/containerised-apps/traffic-gen:traffic-gen"
)

APT_PACKAGES=(apt-transport-https ca-certificates curl gnupg)

CONTAINER_HOME=/opt/containerised-apps

CONTAINERS=(nzbget plex sonarr syncthing traffic-gen transmission unifi)

fail() {
    echo >&2 '[Failure]' "$@"
    return 1
}

warn() {
    echo >&2 '[Warning]' "$@"
}

info() {
    echo "$@"
}
users() {
    # Loop through users and create/update them
    for user in "${USERS[@]}"; do
        name="$(echo "${user}" | cut -d : -f 1)"
        fullname="$(echo "${user}" | cut -d : -f 2)"
        uid="$(echo "${user}" | cut -d : -f 3)"
        shell="$(echo "${user}" | cut -d : -f 4)"
        home="$(echo "${user}" | cut -d : -f 5)"
        groups="$(echo "${user}" | cut -d : -f 6)"
        if id -g "${name}" >/dev/null 2>&1; then
            info Updating group "${name}"
            sudo groupmod -g "${uid}" "${name}"
        else
            info Creating group "${name}"
            sudo groupadd -g "${uid}" "${name}"
        fi
        if id -u "${name}" >/dev/null 2>&1; then
            info Updating user "${name}"
            sudo usermod -c "${fullname}" -u "${uid}" -g "${uid}" -d "${home}" -aG "${groups}" -s "${shell}" "${name}"
        else
            info Creating user "${name}"
            sudo useradd -c "${fullname}" -M -u "${uid}" -g "${uid}" -d "${home}" -G "${groups}" -s "${shell}" "${name}"
        fi
    done
}

packages() {
    install_apt_packages
}

install_docker() {
    # Set up Docker IPv6 support
    if [ ! -f /etc/docker/daemon.json ]; then
        cat <<'EOF' | sudo tee /etc/docker/daemon.json >/dev/null
{
  "ipv6": true,
  "fixed-cidr-v6": "fd00::/80",
  "experimental": true, 
  "ip6tables": true
}
EOF
    fi

    # Install upstream Docker
    if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(grep VERSION_CODENAME /etc/os-release | cut -f 2 -d =) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

    APT_PACKAGES=(docker-ce docker-ce-cli containerd.io)
    install_apt_packages
    DEBIAN_FRONTEND="noninteractive" sudo apt-get update

    # Install a Docker IPv6 NAT tool (hacky, but effective)
    #docker run -d --name ipv6nat --cap-add NET_ADMIN --cap-add SYS_MODULE --network host --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock:ro -v /lib/modules:/lib/modules:ro robbertkl/ipv6nat
}

containers() {
    for container in "${CONTAINERS[@]}"; do
        if [ "$(docker container inspect -f '{{.State.Running}}' "${container}" 2>/dev/null)" != true ]; then
            "${CONTAINER_HOME}/${container}/start.sh"
        fi
    done
}

install_apt_packages() {
    INSTALL_PACKAGES=()
    for package in "${APT_PACKAGES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
            INSTALL_PACKAGES+=("${package}")
        fi
    done
    if [[ -n "${INSTALL_PACKAGES[*]}" ]]; then
        info Installing packages "${INSTALL_PACKAGES[@]}"
        DEBIAN_FRONTEND="noninteractive" sudo apt-get -y install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
    fi
}

main() {
    users
    packages
    install_docker
    containers
}

main

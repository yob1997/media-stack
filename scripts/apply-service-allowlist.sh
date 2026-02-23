#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/service-allowlist.conf}"
DOCKER_CHAIN_NAME="MEDIA_ALLOWLIST_DOCKER"
HOST_CHAIN_NAME="MEDIA_ALLOWLIST_HOST"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE"
  echo "Copy and edit: $SCRIPT_DIR/service-allowlist.conf.example -> $SCRIPT_DIR/service-allowlist.conf"
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

if [[ "${#ALLOWED_SOURCES[@]}" -eq 0 ]]; then
  echo "ALLOWED_SOURCES is empty in $CONFIG_FILE"
  exit 1
fi

if [[ "${#PROTECTED_TCP_PORTS[@]}" -eq 0 ]]; then
  echo "PROTECTED_TCP_PORTS is empty in $CONFIG_FILE"
  exit 1
fi

if ! declare -p HOST_TCP_PORTS >/dev/null 2>&1; then
  HOST_TCP_PORTS=()
fi

is_valid_port() {
  local p="$1"
  [[ "$p" =~ ^[0-9]{1,5}$ ]] && (( p >= 1 && p <= 65535 ))
}

for p in "${PROTECTED_TCP_PORTS[@]}"; do
  if ! is_valid_port "$p"; then
    echo "Invalid port in PROTECTED_TCP_PORTS: '$p'"
    exit 1
  fi
done

for p in "${HOST_TCP_PORTS[@]}"; do
  if [[ -z "$p" ]]; then
    continue
  fi
  if ! is_valid_port "$p"; then
    echo "Invalid port in HOST_TCP_PORTS: '$p'"
    exit 1
  fi
done

CLEAN_HOST_TCP_PORTS=()
for p in "${HOST_TCP_PORTS[@]}"; do
  if [[ -n "$p" ]]; then
    CLEAN_HOST_TCP_PORTS+=("$p")
  fi
done

if ! command -v iptables >/dev/null 2>&1; then
  echo "iptables is required but not installed."
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required when running as non-root."
    exit 1
  fi
  sudo -v
  SUDO="sudo"
fi

if ! ${SUDO} iptables -S DOCKER-USER >/dev/null 2>&1; then
  echo "DOCKER-USER chain not found. Ensure Docker is running and try again."
  exit 1
fi

PORTS_CSV="$(IFS=,; echo "${PROTECTED_TCP_PORTS[*]}")"

${SUDO} iptables -N "$DOCKER_CHAIN_NAME" 2>/dev/null || true
${SUDO} iptables -F "$DOCKER_CHAIN_NAME"

for src in "${ALLOWED_SOURCES[@]}"; do
  ${SUDO} iptables -A "$DOCKER_CHAIN_NAME" \
    -p tcp \
    -m multiport --dports "$PORTS_CSV" \
    -s "$src" \
    -j RETURN
done

# Drop all other sources for protected service ports.
${SUDO} iptables -A "$DOCKER_CHAIN_NAME" \
  -p tcp \
  -m multiport --dports "$PORTS_CSV" \
  -j DROP

# Continue normal processing for all other traffic.
${SUDO} iptables -A "$DOCKER_CHAIN_NAME" -j RETURN

if ! ${SUDO} iptables -C DOCKER-USER -j "$DOCKER_CHAIN_NAME" >/dev/null 2>&1; then
  ${SUDO} iptables -I DOCKER-USER 1 -j "$DOCKER_CHAIN_NAME"
fi

if [[ "${#CLEAN_HOST_TCP_PORTS[@]}" -gt 0 ]]; then
  HOST_PORTS_CSV="$(IFS=,; echo "${CLEAN_HOST_TCP_PORTS[*]}")"

  ${SUDO} iptables -N "$HOST_CHAIN_NAME" 2>/dev/null || true
  ${SUDO} iptables -F "$HOST_CHAIN_NAME"

  for src in "${ALLOWED_SOURCES[@]}"; do
    ${SUDO} iptables -A "$HOST_CHAIN_NAME" \
      -p tcp \
      -m multiport --dports "$HOST_PORTS_CSV" \
      -s "$src" \
      -j RETURN
  done

  ${SUDO} iptables -A "$HOST_CHAIN_NAME" \
    -p tcp \
    -m multiport --dports "$HOST_PORTS_CSV" \
    -j DROP

  ${SUDO} iptables -A "$HOST_CHAIN_NAME" -j RETURN

  if ! ${SUDO} iptables -C INPUT -j "$HOST_CHAIN_NAME" >/dev/null 2>&1; then
    ${SUDO} iptables -I INPUT 1 -j "$HOST_CHAIN_NAME"
  fi
fi

echo "Applied Docker service allowlist via chain: $DOCKER_CHAIN_NAME"
echo "Allowed sources: ${ALLOWED_SOURCES[*]}"
echo "Protected Docker TCP ports: ${PROTECTED_TCP_PORTS[*]}"
if [[ "${#CLEAN_HOST_TCP_PORTS[@]}" -gt 0 ]]; then
  echo "Protected host TCP ports: ${CLEAN_HOST_TCP_PORTS[*]}"
fi
echo
echo "To persist across reboot on Debian/Ubuntu:"
echo "  sudo apt-get install -y iptables-persistent"
echo "  sudo netfilter-persistent save"

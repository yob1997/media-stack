#!/usr/bin/env bash
set -euo pipefail

DOCKER_CHAIN_NAME="MEDIA_ALLOWLIST_DOCKER"
HOST_CHAIN_NAME="MEDIA_ALLOWLIST_HOST"

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

if ${SUDO} iptables -S DOCKER-USER >/dev/null 2>&1; then
  while ${SUDO} iptables -C DOCKER-USER -j "$DOCKER_CHAIN_NAME" >/dev/null 2>&1; do
    ${SUDO} iptables -D DOCKER-USER -j "$DOCKER_CHAIN_NAME"
  done
fi

if ${SUDO} iptables -S INPUT >/dev/null 2>&1; then
  while ${SUDO} iptables -C INPUT -j "$HOST_CHAIN_NAME" >/dev/null 2>&1; do
    ${SUDO} iptables -D INPUT -j "$HOST_CHAIN_NAME"
  done
fi

if ${SUDO} iptables -S "$DOCKER_CHAIN_NAME" >/dev/null 2>&1; then
  ${SUDO} iptables -F "$DOCKER_CHAIN_NAME"
  ${SUDO} iptables -X "$DOCKER_CHAIN_NAME"
fi

if ${SUDO} iptables -S "$HOST_CHAIN_NAME" >/dev/null 2>&1; then
  ${SUDO} iptables -F "$HOST_CHAIN_NAME"
  ${SUDO} iptables -X "$HOST_CHAIN_NAME"
fi

echo "Removed allowlist chains: $DOCKER_CHAIN_NAME, $HOST_CHAIN_NAME"

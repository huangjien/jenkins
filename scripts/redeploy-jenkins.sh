#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
LEGACY_HOME="/Volumes/Windows/Jenkins/data"

mkdir -p "${LEGACY_HOME}"

echo "[redeploy] Using compose file: ${COMPOSE_FILE}"
echo "[redeploy] JENKINS_HOME_BIND=${LEGACY_HOME}"
JENKINS_HOME_BIND="${LEGACY_HOME}" docker compose -f "${COMPOSE_FILE}" down
JENKINS_HOME_BIND="${LEGACY_HOME}" docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[redeploy] Jenkins is redeployed."
echo "[redeploy] URL: http://localhost:8888"

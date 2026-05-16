#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
LEGACY_HOME="/Volumes/Windows/Jenkins/data"
DEFAULT_EXTERNAL_URL="http://imac.tail94eaca.ts.net:8888/"
EXTERNAL_URL="${EXTERNAL_URL:-${DEFAULT_EXTERNAL_URL}}"

mkdir -p "${LEGACY_HOME}"

echo "[redeploy] Using compose file: ${COMPOSE_FILE}"
echo "[redeploy] JENKINS_HOME_BIND=${LEGACY_HOME}"
echo "[redeploy] EXTERNAL_URL=${EXTERNAL_URL}"
JENKINS_HOME_BIND="${LEGACY_HOME}" EXTERNAL_URL="${EXTERNAL_URL}" docker compose -f "${COMPOSE_FILE}" down
JENKINS_HOME_BIND="${LEGACY_HOME}" EXTERNAL_URL="${EXTERNAL_URL}" docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[redeploy] Jenkins is redeployed."
echo "[redeploy] Local URL: http://localhost:8888"
echo "[redeploy] External URL: ${EXTERNAL_URL}"

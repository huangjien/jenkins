#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"

mkdir -p "${REPO_ROOT}/.jenkins_home"

echo "[redeploy] Using compose file: ${COMPOSE_FILE}"
docker compose -f "${COMPOSE_FILE}" down
docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[redeploy] Jenkins is redeployed."
echo "[redeploy] URL: http://localhost:8888"

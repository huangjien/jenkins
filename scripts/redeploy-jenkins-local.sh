#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
LOCAL_HOME="${REPO_ROOT}/.jenkins_home"

mkdir -p "${LOCAL_HOME}"

echo "[redeploy-local] Using compose file: ${COMPOSE_FILE}"
echo "[redeploy-local] JENKINS_HOME_BIND=${LOCAL_HOME}"
JENKINS_HOME_BIND="${LOCAL_HOME}" docker compose -f "${COMPOSE_FILE}" down
JENKINS_HOME_BIND="${LOCAL_HOME}" docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[redeploy-local] Jenkins is redeployed with local home."
echo "[redeploy-local] URL: http://localhost:8888"

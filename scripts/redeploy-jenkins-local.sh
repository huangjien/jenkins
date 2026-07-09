#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
LOCAL_HOME="${REPO_ROOT}/.jenkins_home"
DEFAULT_EXTERNAL_URL="http://imac.tail94eaca.ts.net:8888/"
EXTERNAL_URL="${EXTERNAL_URL:-${DEFAULT_EXTERNAL_URL}}"
JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER:-huangjien}"
JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP:-authenticated}"

mkdir -p "${LOCAL_HOME}"

echo "[redeploy-local] Using compose file: ${COMPOSE_FILE}"
echo "[redeploy-local] JENKINS_HOME_BIND=${LOCAL_HOME}"
echo "[redeploy-local] EXTERNAL_URL=${EXTERNAL_URL}"
echo "[redeploy-local] JENKINS_ADMIN_USER=${JENKINS_ADMIN_USER}"
echo "[redeploy-local] JENKINS_DEVELOPER_GROUP=${JENKINS_DEVELOPER_GROUP}"
if [[ -z "${GITHUB_OAUTH_CLIENT_ID:-}" || -z "${GITHUB_OAUTH_CLIENT_SECRET:-}" ]]; then
  echo "[redeploy-local] WARNING: GitHub OAuth environment variables are not fully set."
fi
JENKINS_HOME_BIND="${LOCAL_HOME}" EXTERNAL_URL="${EXTERNAL_URL}" JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER}" JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP}" docker compose -f "${COMPOSE_FILE}" down
JENKINS_HOME_BIND="${LOCAL_HOME}" EXTERNAL_URL="${EXTERNAL_URL}" JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER}" JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP}" docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[redeploy-local] Jenkins is redeployed with local home."
echo "[redeploy-local] Local URL: http://localhost:8888"
echo "[redeploy-local] External URL: ${EXTERNAL_URL}"

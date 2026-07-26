#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
LOCAL_HOME="${REPO_ROOT}/.jenkins_home"
DEFAULT_EXTERNAL_URL="http://imac.tail94eaca.ts.net:8888/"
EXTERNAL_URL="${EXTERNAL_URL:-${DEFAULT_EXTERNAL_URL}}"
JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER:-huangjien}"
JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD:-change-me-please}"
JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP:-authenticated}"

ENV_FILE="${REPO_ROOT}/.jenkins.env"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
  echo "[redeploy-local] Loaded env from ${ENV_FILE}"
fi

mkdir -p "${LOCAL_HOME}"

echo "[redeploy-local] Using compose file: ${COMPOSE_FILE}"
echo "[redeploy-local] JENKINS_HOME_BIND=${LOCAL_HOME}"
echo "[redeploy-local] EXTERNAL_URL=${EXTERNAL_URL}"
echo "[redeploy-local] JENKINS_ADMIN_USER=${JENKINS_ADMIN_USER}"
echo "[redeploy-local] JENKINS_DEVELOPER_GROUP=${JENKINS_DEVELOPER_GROUP}"
echo "[redeploy-local] GITHUB_OAUTH_CLIENT_ID=${GITHUB_OAUTH_CLIENT_ID:-<unset>}"
if [[ -z "${GITHUB_OAUTH_CLIENT_ID:-}" || -z "${GITHUB_OAUTH_CLIENT_SECRET:-}" ]]; then
  echo "[redeploy-local] WARNING: GitHub OAuth environment variables are not fully set."
fi
JENKINS_HOME_BIND="${LOCAL_HOME}" EXTERNAL_URL="${EXTERNAL_URL}" JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER}" JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD}" JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP}" GITHUB_OAUTH_CLIENT_ID="${GITHUB_OAUTH_CLIENT_ID:-}" GITHUB_OAUTH_CLIENT_SECRET="${GITHUB_OAUTH_CLIENT_SECRET:-}" docker compose -f "${COMPOSE_FILE}" down
JENKINS_HOME_BIND="${LOCAL_HOME}" EXTERNAL_URL="${EXTERNAL_URL}" JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER}" JENKINS_ADMIN_PASSWORD="${JENKINS_ADMIN_PASSWORD}" JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP}" GITHUB_OAUTH_CLIENT_ID="${GITHUB_OAUTH_CLIENT_ID:-}" GITHUB_OAUTH_CLIENT_SECRET="${GITHUB_OAUTH_CLIENT_SECRET:-}" docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[redeploy-local] Jenkins is redeployed with local home."
echo "[redeploy-local] Local URL: http://localhost:8888"
echo "[redeploy-local] External URL: ${EXTERNAL_URL}"

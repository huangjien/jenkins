#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
LEGACY_HOME="/Volumes/Windows/Jenkins/data"
DEFAULT_EXTERNAL_URL="http://imac.tail94eaca.ts.net:8888/"
EXTERNAL_URL="${EXTERNAL_URL:-${DEFAULT_EXTERNAL_URL}}"
JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER:-huangjien}"
JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP:-authenticated}"

# Source persistent env (GitHub OAuth, Cloud Run deploy secrets) if present.
# Anything exported in the calling shell wins over the file.
ENV_FILE="${REPO_ROOT}/.jenkins.env"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
  echo "[redeploy] Loaded env from ${ENV_FILE}"
fi

mkdir -p "${LEGACY_HOME}"

echo "[redeploy] Using compose file: ${COMPOSE_FILE}"
echo "[redeploy] JENKINS_HOME_BIND=${LEGACY_HOME}"
echo "[redeploy] EXTERNAL_URL=${EXTERNAL_URL}"
echo "[redeploy] JENKINS_ADMIN_USER=${JENKINS_ADMIN_USER}"
echo "[redeploy] JENKINS_DEVELOPER_GROUP=${JENKINS_DEVELOPER_GROUP}"
echo "[redeploy] GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID:-<unset>}"

JENKINS_HOME_BIND="${LEGACY_HOME}" \
  EXTERNAL_URL="${EXTERNAL_URL}" \
  JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER}" \
  JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP}" \
  GITHUB_CLIENT_ID="${GITHUB_CLIENT_ID:-}" \
  GITHUB_CLIENT_SECRET="${GITHUB_CLIENT_SECRET:-}" \
  GITHUB_OAUTH_CLIENT_ID="${GITHUB_OAUTH_CLIENT_ID:-${GITHUB_CLIENT_ID:-placeholder-client-id}}" \
  GITHUB_OAUTH_CLIENT_SECRET="${GITHUB_OAUTH_CLIENT_SECRET:-${GITHUB_CLIENT_SECRET:-placeholder-client-secret}}" \
  GCP_PROJECT_ID="${GCP_PROJECT_ID:-}" \
  GCP_SA_KEY_JSON="${GCP_SA_KEY_JSON:-}" \
  HOME_UPSTREAM_HOST="${HOME_UPSTREAM_HOST:-}" \
  HOME_UPSTREAM_PORT="${HOME_UPSTREAM_PORT:-}" \
  docker compose -f "${COMPOSE_FILE}" down

JENKINS_HOME_BIND="${LEGACY_HOME}" \
  EXTERNAL_URL="${EXTERNAL_URL}" \
  JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER}" \
  JENKINS_DEVELOPER_GROUP="${JENKINS_DEVELOPER_GROUP}" \
  GITHUB_CLIENT_ID="${GITHUB_CLIENT_ID:-}" \
  GITHUB_CLIENT_SECRET="${GITHUB_CLIENT_SECRET:-}" \
  GITHUB_OAUTH_CLIENT_ID="${GITHUB_OAUTH_CLIENT_ID:-${GITHUB_CLIENT_ID:-placeholder-client-id}}" \
  GITHUB_OAUTH_CLIENT_SECRET="${GITHUB_OAUTH_CLIENT_SECRET:-${GITHUB_CLIENT_SECRET:-placeholder-client-secret}}" \
  GCP_PROJECT_ID="${GCP_PROJECT_ID:-}" \
  GCP_SA_KEY_JSON="${GCP_SA_KEY_JSON:-}" \
  HOME_UPSTREAM_HOST="${HOME_UPSTREAM_HOST:-}" \
  HOME_UPSTREAM_PORT="${HOME_UPSTREAM_PORT:-}" \
  docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[redeploy] Jenkins is redeployed."
echo "[redeploy] Local URL: http://localhost:8888"
echo "[redeploy] External URL: ${EXTERNAL_URL}"


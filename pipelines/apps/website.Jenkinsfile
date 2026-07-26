pipeline {
  agent { label 'docker' }

  options {
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  parameters {
    booleanParam(name: 'FORCE_BUILD', defaultValue: false, description: 'Run pipeline even if main has no new commit.')
  }

  environment {
    SERVICE_NAME = 'blog'
    RUN_REGION = 'europe-west1'
    EDGE_IMAGE_REPO = 'docker.io/huangjien/website-edge'
    WEBSITE_REPO = 'https://github.com/huangjien/website.git'
    WEBSITE_BRANCH = 'main'
    SKIP_PIPELINE = 'false'
    WEBSITE_HEAD_SHA = ''
  }

  stages {
    stage('Detect Main Changes') {
      steps {
        script {
          def headOutput = sh(
            script: "git ls-remote ${env.WEBSITE_REPO} refs/heads/${env.WEBSITE_BRANCH}",
            returnStdout: true
          ).trim()
          if (!headOutput) {
            error("Could not resolve ${env.WEBSITE_REPO} ${env.WEBSITE_BRANCH}")
          }

          def headSha = headOutput.tokenize()[0]
          env.WEBSITE_HEAD_SHA = headSha
          def markerFile = '.website_last_built_sha'
          def lastBuiltSha = fileExists(markerFile) ? readFile(markerFile).trim() : ''

          if (lastBuiltSha && lastBuiltSha == headSha && !params.FORCE_BUILD) {
            env.SKIP_PIPELINE = 'true'
            currentBuild.description = "No changes on ${env.WEBSITE_BRANCH} (${headSha.take(8)})"
            echo currentBuild.description
          } else {
            echo "Detected new commit on ${env.WEBSITE_BRANCH}: ${headSha.take(8)}"
          }
        }
      }
    }

    stage('Checkout Website') {
      when { expression { env.SKIP_PIPELINE != 'true' } }
      steps {
        dir('website') {
          deleteDir()
          git branch: env.WEBSITE_BRANCH, credentialsId: 'gh_token', url: env.WEBSITE_REPO
        }
      }
    }

    stage('Validate') {
      when { expression { env.SKIP_PIPELINE != 'true' } }
      steps {
        dir('website') {
          sh '''
            set -eux
            apt-get update && apt-get install -y procps chromium
            corepack enable
            corepack prepare pnpm@10.33.0 --activate
            pnpm install --color=true
            pnpm lint
            pnpm format:check
            pnpm type-check
            pnpm check:i18n-parity
            pnpm test:ci
            pnpm check:pages-tests
            pnpm build:webpack
            pnpm perf:ci
          '''
          catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
            sh 'CHROME_PATH=/usr/bin/chromium pnpm exec lhci collect --settings.chromeFlags="--no-sandbox --disable-dev-shm-usage"'
          }
          catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
            sh 'pnpm lhci:assert'
          }
        }
      }
    }

    stage('Deploy') {
      when {
        expression { env.SKIP_PIPELINE != 'true' }
      }
      steps {
        dir('website') {
          // The website container must receive all runtime secrets
          // (NEXTAUTH_SECRET, GITHUB_CLIENT_SECRET, OPEN_AI_KEY, etc.) at
          // container start. Without them, NODE_ENV=production is set by
          // the Dockerfile but the runtime guard in
          // src/pages/api/auth/[...nextauth].js trips on the first auth
          // request with "NEXTAUTH_SECRET must be set in production" and
          // every /api/auth/* route returns HTTP 500.
          //
          // The single source of truth is a Jenkins secret FILE credential
          // with id 'website_env_file' — uploaded once via the Jenkins UI
          // (Manage Jenkins > Credentials) and shaped exactly like the
          // project's .env.home: one KEY=VALUE per line, LF line endings.
          //
          // The same file content should mirror the .env.home file on the
          // home machine so docker compose, deploy-home.sh, and this
          // pipeline all see identical env vars.
          withCredentials([file(credentialsId: 'website_env_file', variable: 'WEBSITE_ENV_FILE')]) {
            sh '''#!/usr/bin/env bash
              set -eux

              IMAGE_NAME="website-local"
              CONTAINER_NAME="website-web"
              HOST_PORT="8080"
              CONTAINER_PORT="8080"

              # Fail closed: refuse to deploy a container that doesn't have
              # the production secrets. This turns what was a silent
              # partial-deploy bug into an explicit pipeline failure.
              test -s "${WEBSITE_ENV_FILE}" || {
                echo "ERROR: website_env_file credential is missing or empty." >&2
                echo "Upload it via Jenkins UI: Manage Jenkins > Credentials >" >&2
                echo "System > Global credentials > Add > Secret file," >&2
                echo "ID = website_env_file, file = a copy of .env.home." >&2
                exit 1
              }

              # Sanity check the env file is shaped the way the container
              # expects: at minimum, NEXTAUTH_SECRET must be present and
              # non-empty, or the deploy will fail at first auth request.
              if ! grep -qE '^NEXTAUTH_SECRET=.+' "${WEBSITE_ENV_FILE}"; then
                echo "ERROR: website_env_file does not contain a non-empty NEXTAUTH_SECRET." >&2
                exit 1
              fi

              docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
              docker image rm -f "$IMAGE_NAME" >/dev/null 2>&1 || true

              for cid in $(docker ps -aq --filter "publish=${HOST_PORT}"); do
                docker rm -f "$cid" >/dev/null 2>&1 || true
              done

              docker build -t "$IMAGE_NAME" .
              docker run -d \
                --name "$CONTAINER_NAME" \
                -p "${HOST_PORT}:${CONTAINER_PORT}" \
                --env-file "${WEBSITE_ENV_FILE}" \
                "$IMAGE_NAME"
              docker ps --filter "name=^/${CONTAINER_NAME}$"

              # Post-deploy verification: assert the secret actually reached
              # the container's runtime environment. This catches any
              # future regression where the --env-file flag is removed or
              # the credential file is replaced with something stale.
              SECRET_LEN=$(docker exec "$CONTAINER_NAME" \
                sh -c 'printf %s "$NEXTAUTH_SECRET" | wc -c' 2>/dev/null || echo 0)
              if [ "$SECRET_LEN" -lt 32 ]; then
                echo "ERROR: NEXTAUTH_SECRET did not reach the container (len=$SECRET_LEN)." >&2
                docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
                exit 1
              fi
              echo "OK: NEXTAUTH_SECRET reached container (len=$SECRET_LEN)."

              # Hit a route that loads the NextAuth module. If the runtime
              # guard inside [...nextauth].js fires (SECRET missing in
              # NODE_ENV=production), the route will throw and return 500.
              #
              # Wait until the Next.js standalone server is actually ready
              # before probing — the Dockerfile's HEALTHCHECK polls
              # /api/health, but that uses the container's internal view.
              # Probe externally from the host:port the user will hit.
              #
              # The container's first request after `docker run` can take
              # >5s to return 200 even on a healthy build, because:
              #   - Next.js standalone boots lazily on first request;
              #   - the `health: starting` window obscures readiness; and
              #   - cold compilation of the route module takes time.
              # A static `sleep 2` is racy and causes false-negative 500s
              # (observed in build #1487), so poll up to 60s instead.
              #
              # Build #1488 failure mode: /api/health returned 200 AND
              # /api/auth/providers returned 500 in the same millisecond,
              # with empty container logs. Capture the response body from
              # now on so the actual error message is visible.
              PROVIDER_RESP=$(mktemp)
              READY=0
              # Build #1491 / #1493 failure mode: the agent container
              # (a temporary Jenkins Java agent on a docker cloud)
              # does not share network namespace with the website
              # container it just started. `localhost:8080` inside the
              # agent resolves to the agent's own loopback, NOT the
              # website container, so every probe was returning 500
              # (Jenkins's own 401/403 surfaced as 500) and the deploy
              # never got off the ground.
              #
              # The agent and the host share /var/run/docker.sock, so
              # the cleanest way to probe the website container is
              # `docker exec` — that runs the probe *inside* the
              # website container's own network namespace, where
              # localhost:8080 actually points to the Next.js server.
              #
              # Build #1491 also surfaced a separate cold-start race:
              # the first request to /api/auth/providers right after
              # `docker run` returns "Empty reply from server" because
              # the Next.js standalone server has not finished
              # initialising the route module. So we poll
              # /api/auth/providers inside the readiness loop and only
              # declare the container ready once that returns 200.
              # /api/health alone is NOT a sufficient readiness
              # signal because it does not load the NextAuth module.
              for i in $(seq 1 30); do
                HEALTH=$(docker exec "$CONTAINER_NAME" \
                  wget -qO- --timeout=3 "http://127.0.0.1:${CONTAINER_PORT}/api/health" \
                  >/dev/null 2>&1 && echo 200 || echo 000)
                PROVIDER=$(docker exec "$CONTAINER_NAME" \
                  wget -qO- --timeout=5 "http://127.0.0.1:${CONTAINER_PORT}/api/auth/providers" \
                  >"$PROVIDER_RESP" 2>/dev/null && echo 200 || echo 000)
                if [ "$HEALTH" = "200" ] && [ "$PROVIDER" = "200" ]; then
                  READY=1
                  echo "OK: /api/health=200 and /api/auth/providers=200 after $((i*2))s (probed via docker exec)."
                  break
                fi
                if [ "$((i % 5))" = "0" ]; then
                  echo "WARN: still not ready (t=$((i*2))s, health=$HEALTH, providers=$PROVIDER)..." >&2
                fi
                sleep 2
              done
              if [ "$READY" != "1" ]; then
                echo "ERROR: /api/auth/providers did not return 200 within 60s (last health=$HEALTH, providers=$PROVIDER)." >&2
                echo "--- response body (first 4KB) ---" >&2
                head -c 4096 "$PROVIDER_RESP" >&2 || true
                echo >&2
                echo "--- container logs (last 80 lines) ---" >&2
                docker logs "$CONTAINER_NAME" --tail 80 || true
                rm -f "$PROVIDER_RESP"
                exit 1
              fi
              rm -f "$PROVIDER_RESP"
            '''
          }
        }
      }
    }
  }

  post {
    success {
      script {
        if (env.SKIP_PIPELINE != 'true' && env.WEBSITE_HEAD_SHA?.trim()) {
          writeFile file: '.website_last_built_sha', text: "${env.WEBSITE_HEAD_SHA}\n"
        }
      }
    }
  }
}

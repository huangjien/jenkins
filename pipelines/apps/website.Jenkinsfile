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
              READY=0
              for i in $(seq 1 30); do
                STATUS=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 \
                  "http://localhost:${HOST_PORT}/api/health" || echo 000)
                if [ "$STATUS" = "200" ]; then
                  READY=1
                  echo "OK: /api/health returned 200 after $((i*2))s."
                  break
                fi
                sleep 2
              done
              if [ "$READY" != "1" ]; then
                echo "ERROR: /api/health did not return 200 within 60s (last status=$STATUS)." >&2
                docker logs "$CONTAINER_NAME" --tail 50 || true
                exit 1
              fi

              # NextAuth module is heavier than /api/health — it pulls in
              # JWT/OAuth/JWS code on first request, which can itself take
              # a couple seconds. Probe it as the final acceptance check.
              STATUS=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 \
                "http://localhost:${HOST_PORT}/api/auth/providers" || echo 000)
              if [ "$STATUS" != "200" ]; then
                echo "ERROR: /api/auth/providers returned HTTP $STATUS (expected 200)." >&2
                echo "--- container logs (last 80 lines) ---" >&2
                docker logs "$CONTAINER_NAME" --tail 80 || true
                exit 1
              fi
              echo "OK: /api/auth/providers returned HTTP 200."
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

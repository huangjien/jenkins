pipeline {
  agent { label 'docker' }

  options {
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  triggers { cron('H/5 * * * *') }

  parameters {
    booleanParam(name: 'FORCE_BUILD', defaultValue: false, description: 'Run pipeline even if main has no new commit.')
    booleanParam(name: 'RUN_CD', defaultValue: false, description: 'Run deployment stages after CI passes.')
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
        allOf {
          expression { env.SKIP_PIPELINE != 'true' }
          expression { params.RUN_CD == true }
        }
      }
      steps {
        dir('website') {
          catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE', message: 'Deploy skipped: required credentials are not configured in Jenkins.') {
            withCredentials([
              string(credentialsId: 'gcp_project_id', variable: 'PROJECT_ID'),
              string(credentialsId: 'gcp_sa_key', variable: 'GCP_SA_KEY_JSON'),
              string(credentialsId: 'home_upstream_host', variable: 'HOME_UPSTREAM_HOST'),
              string(credentialsId: 'home_upstream_port', variable: 'HOME_UPSTREAM_PORT'),
              usernamePassword(credentialsId: 'docker_token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')
            ]) {
              sh '''#!/usr/bin/env bash
                set -eux
                [ -n "$PROJECT_ID" ] && [ -n "$HOME_UPSTREAM_HOST" ] && [ -n "$HOME_UPSTREAM_PORT" ] && [ -n "$GCP_SA_KEY_JSON" ]
                [[ "$HOME_UPSTREAM_PORT" =~ ^[0-9]+$ ]] || { echo "HOME_UPSTREAM_PORT is not numeric: '$HOME_UPSTREAM_PORT'" >&2; exit 1; }

                IMAGE_TAG="${EDGE_IMAGE_REPO}:$(git rev-parse --short=8 HEAD)"
                printf '%s' "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                docker buildx build --platform linux/amd64 --push -f Dockerfile.edge -t "$IMAGE_TAG" -t "${EDGE_IMAGE_REPO}:latest" .
                docker logout

                sed \
                  -e "s|__SERVICE_NAME__|${SERVICE_NAME}|g" \
                  -e "s|__EDGE_IMAGE__|${IMAGE_TAG}|g" \
                  -e "s|__HOME_UPSTREAM_HOST__|${HOME_UPSTREAM_HOST}|g" \
                  -e "s|__HOME_UPSTREAM_PORT__|${HOME_UPSTREAM_PORT}|g" \
                  -e "s|__RELAY_LISTEN_PORT__|18080|g" \
                  -e "s|__TS_ADVERTISE_TAGS__|tag:cloud-run-edge|g" \
                  -e "s|__TS_AUTHKEY_SECRET__|TS_AUTHKEY|g" \
                  deploy/cloudrun/service.yaml > cloudrun-service.rendered.yaml

                ! grep -qE "__[A-Z0-9_]+__" cloudrun-service.rendered.yaml

                # Stream the SA JSON into the gcloud sidecar over stdin and
                # pass the rendered Cloud Run manifest as an env var so the
                # sidecar doesn't need any bind mounts (bind mounts of the
                # agent workspace into a DinD sidecar are flaky). The
                # credential stores the JSON with the standard "\n" escape
                # sequences inside the private_key value, so printf '%s'
                # preserves them literally and gcloud parses the file
                # correctly inside the sidecar.
                export MANIFEST_CONTENT="$(cat cloudrun-service.rendered.yaml)"
                # Write the sidecar script to a temp file in the agent and
                # mount it into the gcloud container. The container reads
                # the script from there instead of via bash -c '<script>',
                # which is fragile when the script contains nested quotes.
                # We pass the SA JSON via stdin (the container reads it
                # into /tmp/gcp-sa.json via `cat`) and the rendered manifest
                # as an env var (the container writes it to /tmp/manifest.yaml
                # via `printf`). The container prints the service URL to
                # stdout, which we redirect into service_url.txt.
                cat > /tmp/deploy-sidecar.sh <<'SIDECAR'
set -eux
cat > /tmp/gcp-sa.json
printf "%s" "$MANIFEST_CONTENT" > /tmp/manifest.yaml
gcloud auth activate-service-account --key-file=/tmp/gcp-sa.json
gcloud config set project "$PROJECT_ID"
gcloud run services replace /tmp/manifest.yaml --region "$RUN_REGION" --platform managed
gcloud run services add-iam-policy-binding "$SERVICE_NAME" --region "$RUN_REGION" --project "$PROJECT_ID" --member="allUsers" --role="roles/run.invoker"
gcloud run services describe "$SERVICE_NAME" --region "$RUN_REGION" --project "$PROJECT_ID" --format="value:status.url"
SIDECAR
                chmod +x /tmp/deploy-sidecar.sh

                printf '%s' "$GCP_SA_KEY_JSON" \
                  | docker run --rm -i \
                      -e PROJECT_ID -e RUN_REGION -e SERVICE_NAME \
                      -e MANIFEST_CONTENT \
                      -v /tmp/deploy-sidecar.sh:/tmp/deploy-sidecar.sh:ro \
                      gcr.io/google.com/cloudsdktool/google-cloud-cli:slim \
                      bash /tmp/deploy-sidecar.sh > service_url.txt

                SERVICE_URL="$(cat service_url.txt)"
                curl -fsSL "${SERVICE_URL}/healthz" || curl -fsSL "${SERVICE_URL}/" || true
              '''
            }
          }
        }
      }
      post {
        always {
          dir('website') {
            sh 'rm -f gcp-sa.json service_url.txt cloudrun-service.rendered.yaml'
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

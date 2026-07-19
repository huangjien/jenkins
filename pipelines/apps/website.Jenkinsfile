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
          def previousDescription = currentBuild.previousSuccessfulBuild?.description ?: ''
          def previousShaMatch = previousDescription =~ /\[website-sha:([0-9a-f]{40})\]/
          def lastBuiltSha = previousShaMatch ? previousShaMatch[0][1] : ''

          if (lastBuiltSha && lastBuiltSha == headSha && !params.FORCE_BUILD) {
            env.SKIP_PIPELINE = 'true'
            currentBuild.description = "No changes on ${env.WEBSITE_BRANCH} (${headSha.take(8)}) [website-sha:${headSha}]"
            echo currentBuild.description
          } else {
            currentBuild.description = "Queued ${env.WEBSITE_BRANCH} (${headSha.take(8)}) [website-sha:${headSha}]"
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
              sh '''
                set -eux
                [ -n "$PROJECT_ID" ] && [ -n "$HOME_UPSTREAM_HOST" ] && [ -n "$HOME_UPSTREAM_PORT" ] && [ -n "$GCP_SA_KEY_JSON" ]
                [[ "$HOME_UPSTREAM_PORT" =~ ^[0-9]+$ ]]

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
                printf '%s' "$GCP_SA_KEY_JSON" > gcp-sa.json

                docker run --rm -v "$PWD":/workspace -w /workspace \
                  -e PROJECT_ID -e RUN_REGION -e SERVICE_NAME \
                  gcr.io/google.com/cloudsdktool/google-cloud-cli:slim sh -lc '
                    set -eux
                    gcloud auth activate-service-account --key-file=/workspace/gcp-sa.json
                    gcloud config set project "$PROJECT_ID"
                    gcloud run services replace /workspace/cloudrun-service.rendered.yaml --region "$RUN_REGION" --platform managed
                    gcloud run services add-iam-policy-binding "$SERVICE_NAME" --region "$RUN_REGION" --project "$PROJECT_ID" --member="allUsers" --role="roles/run.invoker"
                    gcloud run services describe "$SERVICE_NAME" --region "$RUN_REGION" --project "$PROJECT_ID" --format="value(status.url)" > /workspace/service_url.txt
                  '

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
        if (env.WEBSITE_HEAD_SHA?.trim()) {
          def statusPrefix = env.SKIP_PIPELINE == 'true' ? 'No changes on' : 'Built'
          currentBuild.description = "${statusPrefix} ${env.WEBSITE_BRANCH} (${env.WEBSITE_HEAD_SHA.take(8)}) [website-sha:${env.WEBSITE_HEAD_SHA}]"
        }
      }
    }
  }
}

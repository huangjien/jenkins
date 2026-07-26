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
          sh '''#!/usr/bin/env bash
            set -eux

            IMAGE_NAME="website-local"
            CONTAINER_NAME="website-web"
            HOST_PORT="8080"
            CONTAINER_PORT="8080"

            docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
            docker image rm -f "$IMAGE_NAME" >/dev/null 2>&1 || true

            for cid in $(docker ps -aq --filter "publish=${HOST_PORT}"); do
              docker rm -f "$cid" >/dev/null 2>&1 || true
            done

            docker build -t "$IMAGE_NAME" .
            docker run -d --name "$CONTAINER_NAME" -p "${HOST_PORT}:${CONTAINER_PORT}" "$IMAGE_NAME"
            docker ps --filter "name=^/${CONTAINER_NAME}$"
          '''
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

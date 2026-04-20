pipeline {
  agent { label 'docker' }

  parameters {
    string(name: 'JENKINS_AGENT_TAG', defaultValue: 'latest-jdk25', description: 'Base tag for jenkins/inbound-agent')
    string(name: 'NODE_MAJOR', defaultValue: '24', description: 'NodeSource major version')
    string(name: 'PNPM_VERSION', defaultValue: '10.33.0', description: 'pnpm version prepared by corepack')
    string(name: 'IMAGE_REPO', defaultValue: 'huangjien/jenkins', description: 'Output Docker image repository/name')
    string(name: 'IMAGE_TAG', defaultValue: 'dev', description: 'Output Docker image tag')
    booleanParam(name: 'PUSH_IMAGE', defaultValue: false, description: 'Push image after successful build')
  }

  environment {
    DOCKERFILE_PATH = 'jenkins/jenkins-agent-image/general-agent.Dockerfile'
    BUILD_CONTEXT = 'jenkins'
    FULL_IMAGE_NAME = "${params.IMAGE_REPO}:${params.IMAGE_TAG}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        sh '''
          set -eux
          docker version
          docker build \
            -f "${DOCKERFILE_PATH}" \
            --build-arg JENKINS_AGENT_TAG="${JENKINS_AGENT_TAG}" \
            --build-arg NODE_MAJOR="${NODE_MAJOR}" \
            --build-arg PNPM_VERSION="${PNPM_VERSION}" \
            -t "${FULL_IMAGE_NAME}" \
            "${BUILD_CONTEXT}"
        '''
      }
    }

    stage('Push Image') {
      when {
        expression { return params.PUSH_IMAGE }
      }
      steps {
        withCredentials([string(credentialsId: 'docker_token', variable: 'DOCKER_TOKEN')]) {
          sh '''
            set -eux
            printf '%s' "${DOCKER_TOKEN}" | docker login -u "huangjien" --password-stdin
            docker push "${FULL_IMAGE_NAME}"
            docker logout
          '''
        }
      }
    }
  }
}

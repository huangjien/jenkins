pipeline {
  agent { label 'docker' }

  stages {
    stage('Hello Agent') {
      steps {
        sh 'echo "Running on Docker Agent!"'
        sh 'python3 --version || true'
        sh 'hostname'
        sh 'node -v && pnpm -v'
        sh 'uv --version'
        sh 'git --version'
        sh 'docker --version || true'
      }
    }
  }
}

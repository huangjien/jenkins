pipeline {
  agent any

  stages {
    stage('Build') {
      steps {
        echo 'Building sample app...'
      }
    }

    stage('Test') {
      steps {
        echo 'Running tests...'
      }
    }
  }

  post {
    always {
      notifyBuild(currentBuild.currentResult)
    }
  }
}

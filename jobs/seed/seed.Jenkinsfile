pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Generate Jobs') {
      steps {
        jobDsl(
          targets: 'jobs/templates/*.groovy',
          sandbox: false,
          removedJobAction: 'IGNORE',
          removedViewAction: 'IGNORE'
        )
      }
    }
  }
}

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
          sandbox: true,
          removedJobAction: 'IGNORE',
          removedViewAction: 'IGNORE'
        )
      }
    }
  }
}

pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Approve Pending Signatures') {
      steps {
        script {
          def scriptApproval = org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval.get()
          def pendingSignatures = scriptApproval.getPendingSignatures()

          if (pendingSignatures) {
            for (String signature : pendingSignatures) {
              try {
                scriptApproval.approveSignature(signature)
                echo "Approved signature: ${signature}"
              } catch (Exception e) {
                echo "Could not approve signature ${signature}: ${e.message}"
              }
            }
          }
        }
      }
    }

    stage('Generate Jobs') {
      steps {
        jobDsl(
          targets: 'jobs/templates/*.groovy',
          sandbox: false,
          removedJobAction: 'DELETE',
          removedViewAction: 'DELETE'
        )
      }
    }
  }
}

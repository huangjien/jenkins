multibranchPipelineJob('sample-app-ci') {
  branchSources {
    branchSource {
      source {
        git {
          id('sample-app-ci')
          remote('https://github.com/example/sample-app.git')
          credentialsId('github-readonly')
        }
      }
    }
  }

  factory {
    workflowBranchProjectFactory {
      scriptPath('pipelines/apps/sample-app.Jenkinsfile')
    }
  }
}

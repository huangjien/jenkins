pipelineJob('WST-CI-Pipeline') {
  description('Repo-managed pipeline job for WST using the repository root Jenkinsfile on agent label general-agent.')

  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('https://github.com/huangjien/wst.git')
            credentials('gh_token')
          }
          branch('*/main')
        }
      }
      scriptPath('Jenkinsfile')
      lightweight(true)
    }
  }
}

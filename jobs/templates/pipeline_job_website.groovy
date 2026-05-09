pipelineJob('Website-CI-Pipeline') {
  description('Repo-managed CI/CD pipeline for website. Polls GitHub main branch every 5 minutes and deploys on new commits.')

  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('https://github.com/huangjien/jenkins.git')
            credentials('gh_token')
          }
          branch('*/main')
        }
      }
      scriptPath('pipelines/apps/website.Jenkinsfile')
      lightweight(true)
    }
  }
}

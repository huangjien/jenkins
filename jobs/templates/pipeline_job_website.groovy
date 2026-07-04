pipelineJob('website-ci-cd') {
  description('Repo-managed CI/CD pipeline for website. Seed updates replace local inline config and run on the docker cloud agent.')

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

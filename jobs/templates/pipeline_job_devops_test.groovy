pipelineJob('DevOps-Test-Docker-General-Agent') {
  description('Repo-managed pipeline job for docker agent smoke checks.')

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
      scriptPath('pipelines/apps/devops-test-docker-general-agent.Jenkinsfile')
      lightweight(true)
    }
  }
}

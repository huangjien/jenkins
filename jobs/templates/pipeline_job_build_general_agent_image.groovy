pipelineJob('Build-Docker-General-Agent-Image') {
  description('Builds jenkins/jenkins-agent-image/general-agent.Dockerfile with version args controlled by Jenkins parameters.')

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
      scriptPath('pipelines/apps/build-docker-general-agent-image.Jenkinsfile')
      lightweight(true)
    }
  }
}

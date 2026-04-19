pipelineJob('DevOps-Test-Docker-General-Agent') {
  description('Repo-managed pipeline job for docker agent smoke checks.')

  definition {
    cps {
      script(readFileFromWorkspace('pipelines/apps/devops-test-docker-general-agent.Jenkinsfile'))
      sandbox()
    }
  }
}

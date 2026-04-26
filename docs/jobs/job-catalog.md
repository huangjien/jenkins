# Job Catalog

Use this file to inventory Jenkins jobs and ownership.

| Job Name | Type | Source | Owner | Notes |
|---|---|---|---|---|
| seed-jobs | Pipeline | `jobs/seed/seed.Jenkinsfile` | CI Platform | Generates/updates jobs |
| sample-app-ci | Multibranch | `jobs/templates/multibranch_job.groovy` | App Team | Example entry |
| DevOps-Test-Docker-General-Agent | Pipeline | `jobs/templates/pipeline_job_devops_test.groovy` + `pipelines/apps/devops-test-docker-general-agent.Jenkinsfile` | Platform | Runs on label `docker` backed by Docker cloud image `huangjien/jenkins:latest-jdk25` |
| Build-Docker-General-Agent-Image | Pipeline | `jobs/templates/pipeline_job_build_general_agent_image.groovy` + `pipelines/apps/build-docker-general-agent-image.Jenkinsfile` | Platform | Builds and optionally pushes `huangjien/jenkins` using credential `docker_token` |
| WST-CI-Pipeline | Pipeline | `jobs/templates/pipeline_job_wst.groovy` + `https://github.com/huangjien/wst.git` (`Jenkinsfile`) | App Team | Uses credential `gh_token`; polls SCM every 5 minutes via repo Jenkinsfile triggers |

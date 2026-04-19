# Job Catalog

Use this file to inventory Jenkins jobs and ownership.

| Job Name | Type | Source | Owner | Notes |
|---|---|---|---|---|
| seed-jobs | Pipeline | `jobs/seed/seed.Jenkinsfile` | CI Platform | Generates/updates jobs |
| sample-app-ci | Multibranch | `jobs/templates/multibranch_job.groovy` | App Team | Example entry |
| DevOps-Test-Docker-General-Agent | Pipeline | `jobs/templates/pipeline_job_devops_test.groovy` + `pipelines/apps/devops-test-docker-general-agent.Jenkinsfile` | Platform | Synced from live Jenkins inline script on 2026-04-19 |

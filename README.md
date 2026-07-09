# Jenkins Platform Repository

This repository contains infrastructure-as-code and source code for Jenkins setup, job definitions, and pipeline logic.

## Goals

- Keep Jenkins configuration versioned and reviewable.
- Separate server configuration, job definitions, and pipeline code.
- Provide clear docs for onboarding and operations.

## Project Structure

```text
.
|-- docs/
|   |-- remediation-plan.md
|   |-- project-plan.md
|   |-- structure.md
|   |-- jobs/
|   |   `-- job-catalog.md
|   `-- runbooks/
|       |-- local-jenkins-sync.md
|       |-- redeploy-modes.md
|       `-- seed-job.md
|-- environments/
|   |-- dev.yaml
|   `-- prod.yaml
|-- jenkins/
|   |-- jcasc/
|   |   `-- jenkins.yaml
|   |-- jenkins-agent-image/
|   |   `-- general-agent.Dockerfile
|   |-- Dockerfile
|   `-- plugins.txt
|-- jobs/
|   |-- seed/
|   |   `-- seed-job-config.xml
|   |   `-- seed.Jenkinsfile
|   `-- templates/
|       |-- pipeline_job_build_general_agent_image.groovy
|       `-- pipeline_job_devops_test.groovy
|       |-- pipeline_job_website.groovy
|       |-- pipeline_job_wst.groovy
|       `-- pipeline_job_wst_legacy_disabled.groovy
|-- pipelines/
|   |-- apps/
|   |   |-- build-docker-general-agent-image.Jenkinsfile
|   |   |-- devops-test-docker-general-agent.Jenkinsfile
|   |   |-- sample-app.Jenkinsfile
|   |   `-- website.Jenkinsfile
|   `-- shared/
|       `-- build.groovy
`-- shared-library/
    |-- README.md
    |-- src/org/company/ci/Utils.groovy
    `-- vars/notifyBuild.groovy
```

## How To Use

1. Update Jenkins plugins list in `jenkins/plugins.txt`.
2. Maintain controller configuration in `jenkins/jcasc/jenkins.yaml`.
3. Manage job provisioning logic with seed files in `jobs/seed` and `jobs/templates`.
4. Keep reusable pipeline steps in `shared-library`.
5. Update the related docs in the same PR whenever job templates or Jenkins behavior change.

## Auth And Redeploy Inputs

- Jenkins auth is configured through GitHub OAuth plus Matrix Authorization in `jenkins/jcasc/jenkins.yaml`.
- Required secret env vars:
  - `GITHUB_OAUTH_CLIENT_ID`
  - `GITHUB_OAUTH_CLIENT_SECRET`
- Useful non-secret env vars:
  - `JENKINS_ADMIN_USER` (defaults to `huangjien`)
  - `JENKINS_DEVELOPER_GROUP` (defaults to `authenticated`)
  - `EXTERNAL_URL`

## Local Instance

- Active local Jenkins endpoint: `http://localhost:8888`
- Remote-access endpoint is controlled by `EXTERNAL_URL`
- Current redeploy scripts default `EXTERNAL_URL` to `http://imac.tail94eaca.ts.net:8888/`
- Sync checklist: `docs/runbooks/local-jenkins-sync.md`
- Redeploy modes: `docs/runbooks/redeploy-modes.md`

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
|   |-- project-plan.md
|   |-- structure.md
|   |-- jobs/
|   |   `-- job-catalog.md
|   `-- runbooks/
|       |-- local-jenkins-sync.md
|       `-- seed-job.md
|-- environments/
|   |-- dev.yaml
|   `-- prod.yaml
|-- jenkins/
|   |-- jcasc/
|   |   `-- jenkins.yaml
|   `-- plugins.txt
|-- jobs/
|   |-- seed/
|   |   `-- seed.Jenkinsfile
|   `-- templates/
|       |-- multibranch_job.groovy
|       `-- pipeline_job_devops_test.groovy
|-- pipelines/
|   |-- apps/
|   |   |-- devops-test-docker-general-agent.Jenkinsfile
|   |   `-- sample-app.Jenkinsfile
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
5. Document any changes in `docs`.

## Local Instance

- Active local Jenkins endpoint: `http://localhost:8888`
- Sync checklist: `docs/runbooks/local-jenkins-sync.md`

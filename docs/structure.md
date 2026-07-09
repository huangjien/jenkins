# Repository Structure Guide

## High-Level Directories

- `docs/`: Plans, standards, job inventory, and runbooks.
- `environments/`: Environment-level values for `dev` and `prod`.
- `jenkins/`: Jenkins controller configuration and plugins.
- `jobs/`: Seed pipeline and Job DSL templates.
- `pipelines/`: Jenkinsfile sources for app pipelines and shared scripts.
- `shared-library/`: Reusable Jenkins Shared Library code.

## Naming Conventions

- Jenkinsfiles: `<purpose>.Jenkinsfile`
- Job DSL: `pipeline_job_<purpose>.groovy`
- Docs: kebab-case markdown files
- Shared library vars: lowerCamelCase file names

## Recommended Next Steps

1. Add required plugins to `jenkins/plugins.txt`.
2. Configure credentials and GitHub OAuth inputs for `jenkins/jcasc/jenkins.yaml`.
3. Keep `jobs/templates` aligned with the actual repo-managed Jenkins job set.
4. Register shared library in Jenkins global configuration.
5. Update docs in the same PR whenever Jenkins behavior changes.

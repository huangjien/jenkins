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
- Job DSL: `<job-type>-job.groovy`
- Docs: kebab-case markdown files
- Shared library vars: lowerCamelCase file names

## Recommended Next Steps

1. Add required plugins to `jenkins/plugins.txt`.
2. Configure credentials and security realms in `jenkins/jcasc/jenkins.yaml`.
3. Implement concrete Job DSL in `jobs/templates`.
4. Register shared library in Jenkins global configuration.
5. Run `docs/runbooks/local-jenkins-sync.md` after local Jenkins changes.

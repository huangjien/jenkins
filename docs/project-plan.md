# Jenkins Project Plan

## Scope

- Maintain Jenkins controller setup as code.
- Version and review all job and pipeline sources.
- Standardize folder ownership and update process.

## Milestones

1. Baseline structure and documentation.
2. Jenkins Configuration as Code (JCasC) baseline.
3. Seed job + Job DSL templates.
4. Shared library and pipeline standards.
5. Environment-specific rollout and runbooks.

## Ownership Model

- `jenkins/`: Platform team owns Jenkins controller config.
- `jobs/`: CI platform team owns generated job templates.
- `pipelines/`: App teams own application pipeline definitions.
- `shared-library/`: CI platform team owns reusable steps.
- `docs/`: Shared ownership; keep current with every change.

## Change Workflow

1. Create branch.
2. Update code + docs together.
3. Open PR and request review from responsible owners.
4. Merge after validation in `dev` environment.
5. Promote to `prod` after sign-off.

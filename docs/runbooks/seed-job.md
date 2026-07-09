# Seed Job Runbook

## Purpose

The seed job creates or updates Jenkins jobs from DSL templates in `jobs/templates`.

## Prerequisites

- Job DSL plugin installed.
- Repository accessible from Jenkins.
- Seed job credentials configured.
- Seed job runs Job DSL in sandbox mode.

## Execute

1. Run job: `seed-jobs`.
2. Confirm console output contains `Generated items`.
3. Verify expected jobs exist in Jenkins UI.
4. Confirm removed repo-managed jobs are deleted unless they are still represented by explicit DSL entries.

## Troubleshooting

- Missing plugin: install Job DSL and restart Jenkins.
- Sandbox rejection: update templates to use supported Job DSL constructs instead of disabling sandboxing.
- SCM auth error: verify credentials used by seed job.
- Unexpected job deletion: add the legacy job back as an explicit disabled DSL entry before rerunning the seed job.

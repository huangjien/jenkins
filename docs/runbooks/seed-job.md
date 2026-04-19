# Seed Job Runbook

## Purpose

The seed job creates or updates Jenkins jobs from DSL templates in `jobs/templates`.

## Prerequisites

- Job DSL plugin installed.
- Repository accessible from Jenkins.
- Seed job credentials configured.

## Execute

1. Run job: `seed-jobs`.
2. Confirm console output contains `Generated items`.
3. Verify expected jobs exist in Jenkins UI.

## Troubleshooting

- Missing plugin: install Job DSL and restart Jenkins.
- Script approval required: approve pending scripts in Jenkins security settings.
- SCM auth error: verify credentials used by seed job.

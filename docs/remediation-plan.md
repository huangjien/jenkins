# Jenkins Remediation Plan

## Purpose

This plan turns the current repository review findings into a concrete remediation backlog with execution order, detailed tasks, and verification criteria.

## Scope

This plan addresses the following review findings:

1. Overly permissive Jenkins authorization strategy.
2. Unsandboxed Job DSL execution in the seed job.
3. Non-persistent website pipeline change-detection marker.
4. Repo-managed job drift caused by seed-job retention settings.
5. Documentation drift between repo state and operational docs.
6. Non-reproducible plugin installation due to an unpinned plugin.

## Delivery Principles

- Fix security boundaries before convenience or cleanup work.
- Prefer repo-managed, reproducible configuration over UI-only state.
- Keep docs and runtime behavior aligned in the same change where possible.
- Verify each change in a local Jenkins instance before promoting it.

## Phase 1: Lock Down Access

### Goal

Replace broad authenticated-user admin access with explicit, least-privilege authorization.

### Tasks

- [ ] Inventory current live Jenkins auth settings and compare them with `jenkins/jcasc/jenkins.yaml`.
- [ ] Confirm the intended production model for authentication and authorization:
  - GitHub OAuth for identity.
  - Matrix Authorization for permissions.
- [ ] Define the minimum required Jenkins roles/groups:
  - Administrators.
  - CI maintainers.
  - Read-only or developer users.
- [x] Update `jenkins/jcasc/jenkins.yaml` to replace `loggedInUsersCanDoAnything` with the intended matrix-based policy.
- [x] Externalize any OAuth secrets and other auth-sensitive values through environment variables or credentials injection.
- [x] Document the auth model and secret injection requirements in a runbook.
- [ ] Redeploy local Jenkins with the new JCasC config.
- [x] Redeploy local Jenkins with the new JCasC config.
- [ ] Validate that:
  - admin users retain controller management access;
  - non-admin users cannot manage credentials, plugins, or system configuration;
  - job execution permissions match the intended operating model.

### Acceptance Criteria

- Jenkins no longer grants admin-equivalent power to every authenticated user.
- Auth configuration is fully represented in repo-managed configuration except for secrets.
- The runbook explains how to bootstrap and validate access safely.

## Phase 2: Reduce Seed Job Blast Radius

### Goal

Treat Job DSL execution as a privileged operation and reduce the chance that a repo change becomes unrestricted controller code execution.

### Tasks

- [ ] Review current Job DSL usage in `jobs/templates/*.groovy` and classify which constructs require unsandboxed execution.
- [x] Evaluate whether the current templates can run with `sandbox: true`.
- [ ] If sandboxing is feasible:
  - [x] update `jobs/seed/seed.Jenkinsfile` to enable sandboxing;
  - [ ] capture any required script approvals during local validation;
  - [x] document the approval process in `docs/runbooks/seed-job.md`.
- [ ] If sandboxing is not feasible:
  - [ ] document why unsandboxed execution is required;
  - [ ] restrict who can modify seed-job inputs through branch protections and code owner review;
  - [ ] document the seed job as privileged infrastructure code.
- [ ] Verify the seed job can still generate all expected jobs after the chosen approach.

### Acceptance Criteria

- The repository has an explicit, documented decision on Job DSL sandboxing.
- Seed job execution risk is either reduced technically or controlled operationally.
- The seed-job runbook reflects the actual approval and execution model.

## Phase 3: Fix Website Pipeline Change Detection

### Goal

Make the website pipeline skip logic durable across runs instead of depending on ephemeral workspace state.

### Tasks

- [ ] Confirm how Docker cloud agents persist or discard workspace data in the current setup.
- [ ] Choose a durable state strategy for the website pipeline. Recommended options:
  - store the last successful website SHA in Jenkins build metadata or job properties;
  - archive and retrieve a small state artifact;
  - persist the marker in a stable path outside ephemeral agent workspaces.
- [x] Update `pipelines/apps/website.Jenkinsfile` to use the chosen durable storage mechanism.
- [x] Preserve the `FORCE_BUILD` override behavior.
- [ ] Verify the pipeline behavior with three cases:
  - first run with no prior state;
  - repeat run with unchanged `main`;
  - run after a new upstream commit.
- [x] Update the job catalog or runbook to describe the new skip behavior.

### Acceptance Criteria

- The pipeline reliably skips unchanged upstream revisions across separate runs.
- Manual override still works.
- The mechanism does not depend on an ephemeral agent workspace surviving.

## Phase 4: Eliminate Job Drift

### Goal

Ensure repo-managed jobs actually converge Jenkins toward the repository state.

### Tasks

- [ ] Decide the desired behavior for removed or renamed jobs managed by the seed job.
- [x] Update `jobs/seed/seed.Jenkinsfile` so removed jobs and views are handled intentionally rather than ignored.
- [ ] Define a migration approach for legacy jobs that must remain visible temporarily:
  - keep them as explicit disabled DSL entries; or
  - delete them after a scheduled transition period.
- [x] Review committed job XML artifacts, including `website-ci-cd.xml`, and decide whether they are still needed.
- [x] Remove obsolete XML artifacts or clearly mark them as reference-only documents outside the active provisioning path.
- [ ] Run the seed job in local Jenkins and confirm generated jobs match the repository definitions.

### Acceptance Criteria

- Jenkins no longer accumulates stale repo-managed jobs silently.
- Legacy jobs are retained only by explicit policy, not by accidental drift.
- Active provisioning sources are unambiguous.

## Phase 5: Repair Documentation Drift

### Goal

Restore docs as a trustworthy operational source of truth.

### Tasks

- [x] Audit `README.md`, `docs/jobs/job-catalog.md`, and runbooks against the current repo tree and generated jobs.
- [x] Remove references to files that no longer exist, including obsolete examples.
- [x] Correct job descriptions so they match current trigger behavior and ownership.
- [x] Update the project structure section in `README.md` to reflect the actual repository contents.
- [ ] Add a lightweight documentation maintenance rule:
  - [x] every Jenkins job template change must update the relevant docs in the same PR.
- [x] Reconcile remote endpoint documentation so the documented URL matches the intended current deployment model.

### Acceptance Criteria

- Referenced files actually exist.
- Job inventory matches the jobs the seed process is intended to manage.
- README and runbooks reflect current operational behavior.

## Phase 6: Make Controller Builds Reproducible

### Goal

Remove avoidable nondeterminism from Jenkins image builds.

### Tasks

- [x] Pin the `rebuild` plugin version in `jenkins/plugins.txt`.
- [x] Review whether any other dependency versions are floating indirectly and should be captured more explicitly.
- [x] Rebuild the Jenkins controller image locally and confirm plugin resolution succeeds.
- [ ] Record the expected plugin update workflow in docs:
  - [x] how to bump versions;
  - [x] how to validate compatibility;
  - [x] how to redeploy safely.

### Acceptance Criteria

- Plugin installation is deterministic for the declared plugin set.
- Plugin upgrades follow a documented update process.

## Suggested Execution Order

1. Phase 1: Lock Down Access
2. Phase 2: Reduce Seed Job Blast Radius
3. Phase 6: Make Controller Builds Reproducible
4. Phase 4: Eliminate Job Drift
5. Phase 3: Fix Website Pipeline Change Detection
6. Phase 5: Repair Documentation Drift

## Validation Checklist

- [x] Local Jenkins redeploy completes successfully.
- [ ] Seed job runs successfully and produces the expected job set.
- [ ] Non-admin user access is constrained as intended.
- [ ] Website pipeline skip logic behaves correctly across separate runs.
- [x] Docs match actual repository contents and runtime behavior.
- [x] Controller image rebuild is reproducible.

## Recommended Change Breakdown

To keep risk manageable, implement this plan as a small series of pull requests:

1. Security hardening for JCasC auth.
2. Seed job sandboxing decision and controls.
3. Plugin pinning and controller reproducibility cleanup.
4. Seed convergence and stale-job cleanup.
5. Website pipeline state persistence fix.
6. Documentation reconciliation.

## Notes

- Phase 1 and Phase 2 should be treated as blockers before expanding Jenkins usage to additional users or repositories.
- If live Jenkins currently depends on UI-only security settings, capture those settings in JCasC before making any cleanup changes that could overwrite them.
- Local validation on 2026-07-10 confirmed Jenkins boots successfully with `GithubSecurityRealm` + `GlobalMatrixAuthorizationStrategy` applied from JCasC and no matrix-auth security warning after pinning `matrix-auth:3.2.10`.

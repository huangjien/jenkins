# Jenkins Redeploy Modes

## Purpose

This runbook explains the two redeploy modes in this repository and how Jenkins data is selected.

## Modes

### Legacy Mode (default)

- Script: `scripts/redeploy-jenkins.sh`
- Command:

```bash
./scripts/redeploy-jenkins.sh
```

- Data path: `/Volumes/Windows/Jenkins/data`
- Use this mode to keep existing Jenkins jobs, credentials, build history, and settings.

### Local Mode (isolated)

- Script: `scripts/redeploy-jenkins-local.sh`
- Command:

```bash
./scripts/redeploy-jenkins-local.sh
```

- Data path: `./.jenkins_home` (inside this repo)
- Use this mode for local testing without touching legacy Jenkins data.

## How It Is Wired

- Compose file: `docker-compose.yml`
- Jenkins home bind mount:

```yaml
${JENKINS_HOME_BIND:-/Volumes/Windows/Jenkins/data}:/var/jenkins_home
```

- If `JENKINS_HOME_BIND` is not set, Compose uses legacy data path.
- Local mode script sets `JENKINS_HOME_BIND` to repo-local `./.jenkins_home`.

## Safety Notes

- Do not run both modes at the same time using the same container name (`jenkins`).
- Switching modes changes which Jenkins home is mounted; UI state will look different.
- If Jenkins asks for initial admin password, you are likely on a fresh home directory.

## Quick Checks

- Confirm active volume mapping:

```bash
docker inspect --format '{{json .Mounts}}' jenkins
```

- Confirm running jobs from mounted home:

```bash
docker exec jenkins sh -lc 'ls -1 /var/jenkins_home/jobs'
```

# Local Jenkins Sync Runbook

## Scope

Use this runbook to compare the running local Jenkins container and this repository, then sync changes safely.

## Current Live Snapshot (2026-04-19)

- Jenkins URL: `http://localhost:8888` (internally configured as `http://100.76.134.113:8888/`)
- Jenkins version: `2.555.1`
- Security: enabled (`GitHub OAuth` + `Matrix Authorization`)
- Executors: `2`
- Known live job: `DevOps-Test-Docker-General-Agent` (inline pipeline script)

## Verify Live Instance

```bash
curl -I http://localhost:8888/login
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
docker exec jenkins sh -lc 'cat /var/jenkins_home/config.xml | sed -n "1,140p"'
docker exec jenkins sh -lc 'cat /var/jenkins_home/jenkins.model.JenkinsLocationConfiguration.xml'
docker exec jenkins sh -lc 'ls -1 /var/jenkins_home/jobs'
docker exec jenkins sh -lc 'grep -n "removeVolumes" /var/jenkins_home/config.xml'
```

## Verify API Access

```bash
curl -sS -u huangjien:<api-token> http://localhost:8888/crumbIssuer/api/json
curl -sS -u huangjien:<api-token> 'http://localhost:8888/api/json?pretty=true'
curl -sS -u huangjien:<api-token> 'http://localhost:8888/pluginManager/api/json?depth=1'
```

## Sync Rules

1. Keep `jenkins/jcasc/jenkins.yaml` aligned with non-secret settings from live Jenkins.
2. Keep `jenkins/plugins.txt` aligned with plugin versions used in the live instance.
3. Never commit secrets (OAuth client secret, tokens, passwords).
4. Move UI-only jobs into repo (`jobs/` + `pipelines/`) and generate through seed jobs.

## Notes About Auth

- API access to `/api/json` requires valid Jenkins user + API token.
- Validated user in this environment: `huangjien`.
- If a token fails, generate a new API token from the Jenkins user profile and retry.

## Docker Agent Volume Cleanup

- Root cause: Docker cloud agents create anonymous volumes; if `removeVolumes` is false, they remain after agent container removal.
- Desired config: set `removeVolumes: true` in `jenkins/jcasc/jenkins.yaml` Docker template.
- Apply config by redeploying Jenkins, then verify `config.xml` contains `<removeVolumes>true</removeVolumes>`.
- One-time cleanup for leaked volumes:

```bash
docker volume prune -f
```

- Safer targeted cleanup (only dangling volumes):

```bash
docker volume ls -qf dangling=true | xargs -r docker volume rm
```

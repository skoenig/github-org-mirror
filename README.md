# github-org-mirror

Helper scripts for unidirectional, periodic mirroring of repositories in one Github organization to another Github instance.

This can be useful to prepare a migration of the code base from public Github to Github Enterprise or vice versa, or to have a read-only copy of these repositories solely for security scans and code analysis.

## Initial Setup

Following env vars are recognized:

- `SOURCE_HOST` - Github instance which hosts the source repos
- `SOURCE_ORG` - Github organization where the source repos are located
- `SOURCE_TOKEN` - Personal access token to read the source repos, has to have `repo` scope
- `TARGET_HOST` - Github instance to which source repos should be mirrored to
- `TARGET_ORG` - Github organization to which source repos should be mirrored to
- `TARGET_TOKEN` - Personal access token to mirror source repos, has to have `repo` and `user:email` scopes
- `TARGET_USER` - User to which `TARGET_TOKEN` has been issued
- `TARGET_REPO_PREFIX` - Name prefix for target repositories, defaults `SOURCE_ORG`
- `QUIET` - Quiet mode for git, defaults to false

## Mirroring

The `create-repo.sh` script is supposed to create repositories on the target, it can be invoked with a single argument to create exactly that repository:

```
./create-repo.sh "my-fancy-repo"
```

To iterate over all repositories from the source organization and create the corresponding targets, simply omit the argument:

```
./create-repo.sh
```

Similarly, the `mirror.sh` script can be used to regularly sync either a single repository or all repositories from source to target:

```
./mirror.sh ["my-fancy-repo"]
```

## Running in Cloudbuild
To perform this mirroring regularly, for example a Cloudbuild pipeline can be created as follows, which is then triggered via a Cloud Scheduler job at certain intervals.

```
timeout: 1800s
steps:
  - name: gcr.io/cloud-builders/git
    entrypoint: 'bash'
    args:
      - '-c'
      - './create-repo.sh'
    env:
      - 'SOURCE_HOST=github.com'
      - 'SOURCE_ORG=myorg'
      - 'TARGET_HOST=acme.corp.net'
      - 'TARGET_ORG=acme'
    secretEnv:
      - 'SOURCE_TOKEN'
      - 'TARGET_TOKEN'
  - name: gcr.io/cloud-builders/git
    entrypoint: 'bash'
    args:
      - '-c'
      - './mirror.sh'
    env:
      - 'SOURCE_HOST=github.com'
      - 'SOURCE_ORG=myorg'
      - 'TARGET_HOST=acme.corp.net'
      - 'TARGET_ORG=acme'
      - 'TARGET_USER=skoenig'
      - 'QUIET=true'
    secretEnv:
      - 'SOURCE_TOKEN'
      - 'TARGET_TOKEN'
availableSecrets:
  secretManager:
    - versionName: projects/$PROJECT_ID/secrets/github-org-mirror-source-token/versions/latest
      env: 'SOURCE_TOKEN'
    - versionName: projects/$PROJECT_ID/secrets/github-org-mirror-target-token/versions/latest
      env: 'TARGET_TOKEN'
```

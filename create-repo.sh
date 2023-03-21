#!/usr/bin/env bash
set -euo pipefail

repo_prefix=${TARGET_REPO_PREFIX:-"${SOURCE_ORG}"}

. common.sh

if [ "$#" -eq 0 ]
then
    repos=$( list_repos ${SOURCE_HOST} ${SOURCE_ORG} ${SOURCE_TOKEN} )
else
    repos=${1}
fi

for repo_name in $repos
do
    echo $repo_name
    if ! repo_exists "${repo_prefix}-${repo_name}"
    then
        curl -sS \
            -H "Accept: application/vnd.github.nebula-preview+json" \
            -H "Content-Type: application/json" \
            -H "Authorization: token ${TARGET_TOKEN}" \
            -H "User-Agent: $USER_AGENT" \
            --data "{\"name\":\"${repo_prefix}-${repo_name}\",\"visibility\":\"private\"}"  \
            -X POST https://${TARGET_HOST}/api/v3/orgs/${TARGET_ORG}/repos
    fi
done
# vim: ts=4 sw=4 sts=4 et

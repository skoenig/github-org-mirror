#!/usr/bin/env bash
set -euo pipefail

repo_prefix=${TARGET_REPO_PREFIX:-"${SOURCE_ORG}"}
quiet_mode=${QUIET:-false}
git_options=""
[ "$quiet_mode" = true ] && git_options=" --quiet"

. common.sh

function clone_source_repo {
    git clone $git_options --bare https://${SOURCE_TOKEN}@${SOURCE_HOST}/${SOURCE_ORG}/${repo_name}.git
}

function mirror {
    git -C ${repo_name}.git remote set-url --push origin https://${TARGET_USER}:${TARGET_TOKEN}@${TARGET_HOST}/${TARGET_ORG}/${repo_prefix}-${repo_name}.git
    git -C ${repo_name}.git config --replace-all remote.origin.fetch '+refs/heads/*:refs/heads/*'
    git -C ${repo_name}.git config --add remote.origin.fetch '+refs/tags/*:refs/tags/*'
    git -C ${repo_name}.git config remote.origin.mirror true
    git -C ${repo_name}.git fetch $git_options -p origin
    git -C ${repo_name}.git push $git_options --mirror || warn "error syncing repo ${repo_prefix}-${repo_name}"
}

if [ "$#" -eq 0 ]
then
    repos=$( list_repos ${SOURCE_HOST} ${SOURCE_ORG} ${SOURCE_TOKEN} )
else
    repos=${1}
fi

for repo_name in $repos
do
    if ! repo_exists "${repo_prefix}-${repo_name}"
    then
        warn "target repo ${repo_prefix}-${repo_name} does not exist, skipping"
        continue
    fi

    if [ ! -d ${repo_name}.git ]
    then
        clone_source_repo
    fi

    mirror
done

# vim: ts=4 sw=4 sts=4 et

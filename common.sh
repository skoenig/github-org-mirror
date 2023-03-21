#!/usr/bin/env bash
set -euo pipefail

USER_AGENT="github-org-mirror/1.0"

function fail {
    msg=$1
    echo >&2 "ERROR: $msg"
    exit 1
}

function warn {
    msg=$1
    echo >&2 "WARN: $msg"
}

function repo_exists {
    if [[ $(curl -s -w "%{http_code}" -o /dev/null \
        -H "Accept: application/vnd.github.nebula-preview+json" \
        -H "Content-Type: application/json" \
        -H "Authorization: token ${TARGET_TOKEN}" \
        -H "User-Agent: $USER_AGENT" \
        https://${TARGET_HOST}/api/v3/repos/${TARGET_ORG}/${1}) == "200" ]]
    then
        true
    else
        false
    fi
}

function list_repos {
    local host=${1}
    local org=${2}
    local token=${3}
    local basepath

    if [[ ${host} == "github.com" ]]
    then
        basepath="https://api.${host}"
    else
        # Use this case if a GHE instance is configured to not use the default
        # subdomain to expose its API.
        basepath="https://${host}/api/v3"
    fi

    url="${basepath}/orgs/${org}/repos"
    last_page=$(get_last_page "$url" "$token")
    for ((i=1;i<=last_page;i++))
    do
    curl -sS \
        -H "application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -H "Authorization: token ${token}" \
        "${url}?page=${i}" | jq -r .[].name
    done
}

function get_last_page {
    local url=${1}
    local token=${2}

    # single page results (no pagination) do not have a 'Link' header
    set +o pipefail
    local last_page=$(
    curl -sS -I \
        -H "application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -H "Authorization: token ${token}" \
        -H "User-Agent: $USER_AGENT" \
        ${url} \
        | grep -i '^link:' \
        | sed -e 's/^.*page=//g' -e 's/>.*$//g'
    )
    set -o pipefail

    if [[ ! $last_page ]]
    then
        echo 1
    else
        echo $last_page
    fi
}
# vim: ts=4 sw=4 sts=4 et

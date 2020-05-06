#!/bin/sh

set -e

prefix=${INPUT_LABEL_PREFIX}
github_token=${INPUT_GITHUB_TOKEN}

run() {
    pull_request=''

    case "${GITHUB_EVENT_NAME}" in
    'push')
        pull_request="$(fetch_merged_pull_request)"
        ;;
    'pull_request')
        pull_request="$(jq '.pull_request' "${GITHUB_EVENT_PATH}")"
        ;;
    *)
        echo "::debug:: event ${GITHUB_EVENT_NAME} not supported"
        ;;
    esac

    if [ -z "${pull_request}" ]; then
        echo "::error:: failed to get pull request event"
    fi

    label=$(echo "${pull_request}" | jq -r ".labels[].name | select(test(\"$prefix(major|premajor|minor|preminor|patch|prepatch|prerelease)\"))")

    if [ -z "${label}" ]; then
        echo "::debug:: no release label"
        exit 0
    fi

    if [ "$(echo "${label}" | wc -l)" -ne 1 ]; then
        echo "::error:: multiple release labels not allowed: labels=$(echo "${label}" | tr '\n' ',')"
        exit 1
    fi

    level=${label#"${prefix}"} # e.g.) 'release/major' => 'major'

    echo "::set-output name=level::${level}"
}

fetch_merged_pull_request() {
    if [ -z "${github_token}" ]; then
        echo "::error:: github token is required for push event"
        exit 1
    fi

    curl -s \
        -H "Authorization: token ${github_token}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls?state=closed&sort=updated&direction=desc" |
        jq -r ".[] | select(.merge_commit_sha==\"${GITHUB_SHA}\")"
}

run

#!/bin/sh

set -e

event=${INPUT_EVENT}
prefix=${INPUT_LABEL_PREFIX}

label=$(echo "${event}" | jq -r ".pull_request.labels[].name | select(test(\"$prefix(major|minor|patch)\"))")

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

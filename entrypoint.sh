#!/bin/sh

set -e

prefix=${INPUT_LABEL_PREFIX}
labels=${INPUT_LABELS}

case "${GITHUB_EVENT_NAME}" in

'push')
    for l in ${labels}; do
        case ${l#"$prefix"} in # e.g.) 'release/major' => 'major'
        'major' | 'minor' | 'patch')
            if [ -z "${label}" ]; then
                label="${l}"
            else
                label="${label}\n${l}"
            fi
            ;;
        esac
    done
    ;;

'pull_request' | 'pull_request_target')
    label=$(jq -r ".pull_request.labels[].name | select(test(\"$prefix(major|minor|patch)\"))" "${GITHUB_EVENT_PATH}")
    ;;

*)
    echo "::debug:: event ${GITHUB_EVENT_NAME} not supported"
    ;;

esac

if [ -z "${label}" ]; then
    echo "::debug:: no release label"
    exit 0
fi

if [ "$(echo "${label}" | wc -l)" -ne 1 ]; then
    echo "::error:: multiple release labels not allowed: labels=$(echo "${label}" | tr '\n' ' ')"
    exit 1
fi

level=${label#"${prefix}"} # e.g.) 'release/major' => 'major'

echo "::set-output name=level::${level}"

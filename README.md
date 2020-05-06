# Action Release Label

[![actions-workflow-lint][actions-workflow-lint-badge]][actions-workflow-lint]
[![release][release-badge]][release]
[![license][license-badge]][license]

![screenshot](./docs/assets/screenshot-labels.png)

This is a GitHub Action to output a semver update level `major`, `minor`, `patch` from a pull request *release label*.

For example, if a pull request has the label `release/minor`, this action outputs `minor` as level.

It would be more useful to use this with other GitHub Actions' outputs.
It's recommended to use this with [actions-ecosystem/action-bump-semver](https://github.com/actions-ecosystem/action-bump-semver) and [actions-ecosystem/action-push-tag](https://github.com/actions-ecosystem/action-push-tag).

This action supports `pull_request` and `push` events.

## Prerequisites

It's necessary to create labels with the `inputs.label_prefix` prefix and the `major`, `minor`, `patch` suffix before getting started with this action.

By default, they're `release/major`, `release/minor`, and `release/patch`.

## Inputs

|      NAME      |                                                                         DESCRIPTION                                                                         |   TYPE   | REQUIRED |  DEFAULT   |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ---------- |
| `label_prefix` | A prefix for labels that indicate semver level {`major`, `minor`, `patch`}.                                                                                 | `string` | `false`  | `release/` |
| `labels`       | The list of labels for the pull request. Separated with line breaks if there're multiple labels. Required for `push` events, not for `pull_request` events. | `string` | `false`  | `N/A`      |

It would be easy to prepare `inputs.labels` with [actions-ecosystem/action-get-merged-pull-request](https://github.com//actions-ecosystem/action-get-merged-pull-request).

## Outputs

|  NAME   |                  DESCRIPTION                   |   TYPE   |
|---------|------------------------------------------------|----------|
| `level` | A semver update level `{major, minor, patch}`. | `string` |

## Example

### Simple

```yaml
name: Push a new tag with Pull Request

on:
  pull_request:
    types: [closed]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - uses: actions-ecosystem/action-release-label@v1
        id: release-label
        if: ${{ github.event.pull_request.merged == true }}

      - uses: actions-ecosystem/action-get-latest-tag@v1
        id: get-latest-tag
        if: ${{ steps.release-label.outputs.level != null }}

      - uses: actions-ecosystem/action-bump-semver@v1
        id: bump-semver
        if: ${{ steps.release-label.outputs.level != null }}
        with:
          current_version: ${{ steps.get-latest-tag.outputs.tag }}
          level: ${{ steps.release-label.outputs.level }}

      - uses: actions-ecosystem/action-push-tag@v1
        if: ${{ steps.release-label.outputs.level != null }}
        with:
          tag: ${{ steps.bump-semver.outputs.new_version }}
          message: '${{ steps.bump-semver.outputs.new_version }}: PR #${{ github.event.pull_request.number }} ${{ github.event.pull_request.title }}'
```

### More Practical

A practical example is below. If you're interested in the latest one, see [.github/workflows/release.yml](.github/workflows/release.yml).

![screenshot](./docs/assets/screenshot-example-pull-request.png)
![screenshot](./docs/assets/screenshot-example-release.png)

With this workflow, you can automatically update a Git tag and create a GitHub release with only adding a *release label* and optionally a *release note* after a pull request has been merged.

1. [actions-ecosystem/action-release-label](https://github.com/actions-ecosystem/action-release-label) gets a semver update level from a *release label*.
2. [actions-ecosystem/action-get-latest-tag](https://github.com/actions-ecosystem/action-get-latest-tag) fetches the latest Git tag in the repository.
3. [actions-ecosystem/action-bump-semver](https://github.com/actions-ecosystem/action-bump-semver) bumps up the Git tag previously fetched based on the semver update level at the step *1*.
4. [actions-ecosystem/action-regex-match](https://github.com/actions-ecosystem/action-regex-match) extracts a *release note* from the pull request body.
5. [actions-ecosystem/action-push-tag](https://github.com/actions-ecosystem/action-push-tag) pushes the bumped Git tag with the pull request reference as a message.
6. [actions/create-release](https://github.com/actions/create-release) creates a GitHub release with the Git tag and the *release note* when the semver update level is *major* or *minor*.
7. *[Optional]* [actions-ecosystem/action-create-comment](https://github.com/actions-ecosystem/action-create-comment) creates a comment that reports the new GitHub release.

For further details, see each action document.

```yaml
name: Create Release

on:
  pull_request:
    types: [closed]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - uses: actions-ecosystem/action-release-label@v1
        id: release-label
        if: ${{ github.event.pull_request.merged == true }}

      - uses: actions-ecosystem/action-get-latest-tag@v1
        id: get-latest-tag
        if: ${{ steps.release-label.outputs.level != null }}

      - uses: actions-ecosystem/action-bump-semver@v1
        id: bump-semver
        if: ${{ steps.release-label.outputs.level != null }}
        with:
          current_version: ${{ steps.get-latest-tag.outputs.tag }}
          level: ${{ steps.release-label.outputs.level }}

      - uses: actions-ecosystem/action-regex-match@v2
        id: regex-match
        if: ${{ steps.release-label.outputs.level != null }}
        with:
          text: ${{ github.event.pull_request.body }}
          regex: '```release_note([\s\S]*)```'

      - uses: actions-ecosystem/action-push-tag@v1
        if: ${{ steps.release-label.outputs.level != null }}
        with:
          tag: ${{ steps.bump-semver.outputs.new_version }}
          message: "${{ steps.bump-semver.outputs.new_version }}: PR #${{ github.event.pull_request.number }} ${{ github.event.pull_request.title }}"

      - uses: actions/create-release@v1
        if: ${{ steps.release-label.outputs.level == 'major' || steps.release-label.outputs.level == 'minor' }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ steps.bump-semver.outputs.new_version }}
          release_name: ${{ steps.bump-semver.outputs.new_version }}
          body: ${{ steps.regex-match.outputs.group1 }}

      - uses: actions-ecosystem/action-create-comment@v1
        if: ${{ steps.bump-semver.outputs.new_version != null }}
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          body: |
            The new version [${{ steps.bump-semver.outputs.new_version }}](https://github.com/${{ github.repository }}/releases/tag/${{ steps.bump-semver.outputs.new_version }}) has been released.
```

## Note

This action is inspired by [haya14busa/action-bumpr](https://github.com/haya14busa/action-bumpr).

## License

Copyright 2020 The Actions Ecosystem Authors.

Action Release Label is released under the [Apache License 2.0](./LICENSE).

<!-- badge links -->

[actions-workflow-lint]: https://github.com/actions-ecosystem/action-release-label/actions?query=workflow%3ALint
[actions-workflow-lint-badge]: https://img.shields.io/github/workflow/status/actions-ecosystem/action-release-label/Lint?label=Lint&style=for-the-badge&logo=github

[release]: https://github.com/actions-ecosystem/action-release-label/releases
[release-badge]: https://img.shields.io/github/v/release/actions-ecosystem/action-release-label?style=for-the-badge&logo=github

[license]: LICENSE
[license-badge]: https://img.shields.io/github/license/actions-ecosystem/action-add-labels?style=for-the-badge

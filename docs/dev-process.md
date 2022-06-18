# Development Process

The main development branch is `main`.

## Releases

Whim has the following release channels:

- `canary`: The latest changes in `main`.
- `beta`: The latest changes in a release branch `release/v*`.
- `stable`: A release of the latest stable version, in a release branch.

Releases follow the format `v<version>-<channel>.<build>.<commit>`. For example, `v5-beta.4.3b8c8aa`.

- `version` is the version number.
- `channel` is the release channel.
- `build` is the number of commits since the bump commit.
- `commit` is the commit hash.

### Canary Releases

`canary` releases are created by making a commit to `main`, typically via a squashed pull request. This will run [`unstable_release.yml`](#unstablereleaseyml).

### Beta Releases

`beta` releases are created by making a commit to a release branch. This will run [`unstable_release.yml`](#unstablereleaseyml).

`beta` release branches are created by running [`scripts\Create-ReleaseBranch.ps1`](#create-releasebranchps1).

### Stable Releases

`stable` releases are running [`scripts\Create-DraftRelease.ps1`](#create-draftreleaseps1) locally.

The [`update_release.yml`](#updatereleaseyml) workflow will then upload artifacts to the release and publish the release.

## Automating Releases

### `unstable_release.yml`

`unstable_release.yml` will create a release draft by running [`scripts\Create-DraftRelease.ps1`](#create-draftreleaseps1).

### `Create-ReleaseBranch.ps1`

`Create-ReleaseBranch.ps1` will:

1. Create a branch to bump the version.
2. Bump the version and push the commit.
3. Create a pull request to `main`.
4. Checkout `main`.
5. Wait for user input checking that the pull request is merged.
6. Create a release branch.
7. Push the release branch, which will trigger [`unstable_release.yml`](#unstablereleaseyml).

### `Create-DraftRelease.ps1`

`Create-DraftRelease.ps1` takes as a parameter the release channel.

It will:

1. Create release version string.
2. Ask for user verification (if `env:CI` is not set).
3. Create release notes.
4. Create draft release, which will trigger [`update_release.yml`](#updatereleaseyml).
5. If `env:CI` is not set, show user link and open in browser.

### `update_release.yml`

The `update_release.yml` workflow will run when a draft release is created.

`update_release.yml` will:

1. Build the release.
2. Upload artifacts to the release.
3. Publish the release.

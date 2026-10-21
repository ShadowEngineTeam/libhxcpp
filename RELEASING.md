# Releasing libhxcpp

A release is a deliberate commit on `main`, tested by CI, then published by the release workflow. Nothing is released on a push, and no version number is counted up for you.

## Versions

libhxcpp uses [semantic versioning](https://semver.org), with its own numbers starting at 6.0.0. They do not follow hxcpp's.

- **Major** (7.0.0): a change that can break a project that built against the previous version: an API, a build define or behaviour that code relies on.
- **Minor** (6.1.0): new features, compatible with what came before.
- **Patch** (6.0.1): fixes only.

Pre-releases use the three tags haxelib accepts, each optionally numbered, in this order:

| Tag | Use |
|---|---|
| `6.0.0-alpha.1` | Early, incomplete; anything may change |
| `6.0.0-beta.1` | Feature complete for the release, still being fixed |
| `6.0.0-rc.1` | A release candidate: the release, unless something is found |

All of them sort before `6.0.0`. haxelib rejects any other suffix, such as `-dev` or `-nightly`. Its client also understands `-preview`, but its server refuses to publish it.

Each release is tagged `v<version>`, published as a GitHub release with `libhxcpp-<version>.zip`, and submitted to haxelib as `libhxcpp`. The GitHub release stays available whatever happens on haxelib.

## The cycle

### 1. Develop on main

The top section of [Changes.md](Changes.md) is the next release, headed with the version `main` is working toward:

```
libhxcpp 6.0.0 (unreleased)
------------------------------------------------------------
```

`haxelib.json` carries the same version. Each pull request that changes something a user would notice adds its line to this section.

### 2. Make the release commit

One commit, and nothing else in it:

- set `"version"` in `haxelib.json` to exactly the version being released, for example `6.0.0-beta.1` or `6.0.0`;
- change the top heading of Changes.md to match it, without "(unreleased)": `libhxcpp 6.0.0-beta.1`.

Check it locally before pushing:

```
haxe -p tools/release --run Release check
haxe -p tools/release --run Release notes notes.md
```

The first runs the same check the release workflow does; the second writes the release notes it will publish.

Push the commit to `main` and wait for the `main` workflow to pass on it. CI skips commits that change only documentation, so run the release on the release commit itself: it changes `haxelib.json`, so CI always runs on it.

### 3. Run the release workflow

In the Actions tab, open **release** and run it on `main` (or on a release branch, see below). It stops without releasing if:

- it is not run on `main` or a `release/<major>.<minor>` branch;
- the version in `haxelib.json` is not one haxelib accepts;
- the top heading of Changes.md does not name that version;
- `v<version>` is already released;
- CI did not pass on the commit. If a failure is known and unrelated, run it again with **allow_failed_ci** and say why in the release notes.

Otherwise it writes the version into `include/HxcppVersion.h` (`HXCPP_VERSION` and `LIBHXCPP_VERSION`) and `extraParams.hxml` (the `libhxcpp` and `hxcpp` defines, set by a macro rather than `-D` lines, which hxp misreads), builds the build tool and the cppia host for Windows, macOS and Linux, tags `v<version>`, and publishes the release with the top section of Changes.md as its notes. A pre-release version is published as a GitHub pre-release.

Then submit the release's zip to haxelib, from an account listed in `contributors` in `haxelib.json`:

```
haxelib submit libhxcpp-<version>.zip
```

haxelib finds the package's `haxelib.json` inside the zip's top folder. Only the accounts in `contributors` can submit a new version of `libhxcpp`, so keep that list to the people who make releases.

### 4. Open the next cycle

Straight after the release, one commit that sets `haxelib.json` to the version `main` now works toward and adds a new section above the released one:

```
libhxcpp 6.0.1 (unreleased)
------------------------------------------------------------
```

After a pre-release, keep working toward the same version: after `6.0.0-beta.1`, go back to `6.0.0 (unreleased)`, and list the changes since the beta.

## Fixes for a released version

While `main` holds only fixes, patch releases come from `main` as above. Once `main` takes a change meant for the next minor or major version, a fix for the released version gets a branch of its own, cut only when the first such fix is needed:

1. Cut `release/<major>.<minor>` from the line's latest tag: `git switch -c release/6.0 v6.0.0`, and push it.
2. Land each fix on `main` first, then cherry-pick it to the branch with `git cherry-pick -x`, so that no fix exists only on a release branch. If a fix does not apply to `main`, say why in its commit message.
3. Release from the branch exactly as from `main`: the release commit, CI passing on it (CI runs on pushes to `release/**`), then the **release** workflow run on the branch. It publishes the release without making it the latest one on GitHub.
4. Copy the version's Changes.md section to `main` as well, below the unreleased one, so the history there stays complete.

Only the latest minor version of a line gets fixes: once 6.1.0 is out, 6.0 fixes stop and `release/6.1` takes them when needed. Before submitting a release branch's version to haxelib, check that `haxelib install libhxcpp` still picks the newest version; if submitting would make the older line the current one, publish it on GitHub only.

## When a release is wrong

Never move or reuse a tag, since someone may already have installed what it points at. Fix it on `main` and release the next version: a patch, or the next pre-release. Say in the new release's notes what was wrong with the old one.

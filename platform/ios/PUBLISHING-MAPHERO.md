# Publishing the MapHero iOS SDK

How a new version of the iOS SDK gets built, released and made installable — and which of the
scripts already in this directory will waste your afternoon if you try them instead.

Everything here is about `idealprojects/maphero-native`. Upstream MapLibre releases differently, and
most of the release machinery in this tree is upstream's.

---

## The short version

```bash
# from a clone of idealprojects/maphero-native, on the release branch
./platform/ios/publish-maphero.sh 1.3.3 --watch
```

That bumps `platform/ios/VERSION`, pushes the branch, pushes the tag `1.3.3`, waits for the build,
and prints the `.binaryTarget` block to paste into `Package.swift` in
[`idealprojects/maphero-ios`](https://github.com/idealprojects/maphero-ios).

Nothing installs the new version until that last paste is committed. The release is the artifact;
`maphero-ios` is what consumers actually resolve.

Useful variants:

| | |
|---|---|
| `--dry-run` | Says what it would do. Writes nothing, pushes nothing. |
| `--verify-only` | For a release that already exists: downloads the asset and prints its checksum. |
| `--watch` | Polls CI, then verifies. Without it the script exits after pushing the tag. |
| `--yes` | Skips the confirmation prompt. |

---

## What actually happens

```
  publish-maphero.sh
        │
        │  git push maphero 1.3.3      ← the only outward-facing step
        ▼
  tag 1.3.3  ──triggers──▶  .github/workflows/maphero-ios-release.yml  (macos-15, ~1–2h)
                                   │
                                   │  bazel build //platform/ios:MapHero.dynamic
                                   │    --compilation_mode=opt --features=dead_strip,thin_lto
                                   ▼
                            GitHub release, tag 1.3.3
                              MapHero_ios_device.framework.zip     ← what SPM fetches
                              MapHero-1.3.3-dSYM.zip
                                   │
                                   ▼
                     Package.swift in idealprojects/maphero-ios
                              url + checksum  ← you commit this
```

**The tag is the authorisation.** It is the only step that reaches the outside world, it publishes
immediately rather than as a draft, and the asset is public the moment the build finishes. Pushing
it is deliberately the thing a human does.

**The tag must be a bare version** — `1.3.3`, not `ios-v1.3.3`. That is the shape
`maphero-ios-release.yml` triggers on, and it is the shape every MapHero release has used since
0.0.1. `ios-*` tags trigger a *different* workflow (upstream's `ios-ci`), which will not release
anything useful — see below.

---

## Why the build is not local

This codebase cannot be built on every Mac. The bazel Apple toolchain needs an Xcode it can
actually drive, and on at least one development machine here (macOS 26 on Intel) the only Xcode
that launches is one the toolchain cannot build against. 1.3.0 and 1.3.1 *were* built by hand on a
Mac, which is why no workflow run exists for either of them, and why their framework zips differ in
size from every release before them.

CI removes that variable: one image, one toolchain, a build you can point at afterwards.

Two facts worth knowing if the image ever has to change:

- **`macos-15`** is what the release workflow uses. It is the image that produced the shipped 1.2.1
  artifact through this same flag set.
- **`macos-14`** is the documented fallback. `ios-ci` builds this same target in opt mode on
  `macos-14` on every run, so it is known to work on this tree — with the size test's flags rather
  than the release flags.
- **Not `macos-latest`.** That now resolves to a macOS 26 image whose SDK headers hard-error on
  code this tree includes.

---

## Do not use these

Both are upstream MapLibre's, both are still in this directory, and neither can work here.

### `ios-ci.yml`'s `ios-release` job

Triggered by **Actions → ios-ci → Run workflow** with `release: pre`. It looks like the obvious
route and it is not:

| | upstream `ios-release` produces | what `maphero-ios` fetches |
|---|---|---|
| tag | `ios-v1.3.3-pre<sha>` — the step **rejects** a version without `pre` | `1.3.3` |
| asset | `MapHero.dynamic.xcframework.zip` | `MapHero_ios_device.framework.zip` |

It also uploads a changelog to `s3://maplibre-native/`, publishes to the Swift Package Index and to
CocoaPods, and its `Configure AWS Credentials` step carries no `if:` guard while this fork sets no
`OIDC_AWS_ROLE_TO_ASSUME` — so it fails on the way there regardless of the naming.

Its `full` release path is gated on `github.ref == 'refs/heads/main'`, and this fork's `main` is at
1.2.1 on a history that diverges from the release branches, so that path is not available either.

### `scripts/deploy-swift-package.sh`

Upstream's, and broken in this fork in four separate ways:

1. It hardcodes `GITHUB_USER=maplibre`, `GITHUB_REPO=maplibre-native` and pushes the resulting
   `Package.swift` to `maplibre/maplibre-gl-native-distribution` — not to `maphero-ios`.
2. It requires `mbx auth` (Mapbox-internal tooling), the `github-release` CLI, `GITHUB_TOKEN` and
   `DIST_GITHUB_TOKEN`.
3. It expects `ios-vX.X.X` tags.
4. The rename broke its substitution: it calls `setTarget "MAPLIBRE" …`, which replaces
   `MAPLIBRE_PACKAGE_URL`, while `scripts/swift_package_template.swift` now says
   `MAPHERO_PACKAGE_URL`. `sed` matches nothing, exits 0, and the published `Package.swift` would
   carry the literal placeholder. The template's product is also still named `Mapbox`, where the
   live package's is `MapHero`.

Left in place rather than deleted, because deleting upstream files is a separate decision. Just
don't run it.

---

## The preconditions, and why each one is there

`publish-maphero.sh` refuses to proceed on any of these. Every one corresponds to something that
has actually gone wrong.

- **The release workflow must exist at the commit being tagged.** A tag build runs the workflow
  file *from the tagged commit*. Tag a commit that predates
  `.github/workflows/maphero-ios-release.yml` and nothing happens: no run, no failure, no
  notification. Silence is the worst failure mode, so this is checked first.
- **`platform/ios/VERSION` must equal the tag.** The workflow checks this too and fails the run,
  but failing here costs seconds instead of an hour. A framework reporting a different version than
  the URL it is fetched by is worse than no release.
- **The tag must not already exist**, locally or on the remote. Moving a released tag changes what
  a pinned checksum refers to and breaks every consumer that already resolved it. Cut a new patch
  version instead.
- **The working tree must be clean**, apart from the `VERSION` bump itself — otherwise the tag does
  not describe what was built.
- **The version must look like `X.Y.Z`.** Checked *before* the file is written, so a typo cannot
  leave an invalid version behind in `VERSION`.
- **A remote must point at `idealprojects/maphero-native`.** It is usually not `origin`: in a clone
  derived from upstream, `origin` is `maplibre/maplibre-native` and the fork is `maphero`.

---

## Reading CI when something fails

**Job logs on this repository need admin rights.** `GET /actions/jobs/<id>/logs` answers
`403: Must have admin rights to Repository`, so if you are not an admin you cannot read why a build
failed from the log.

Check-run **annotations** are readable by anyone who can see the run, which is why both iOS
workflows emit failures as annotations:

```bash
curl -s https://api.github.com/repos/idealprojects/maphero-native/actions/runs/<run id>/jobs
curl -s https://api.github.com/repos/idealprojects/maphero-native/check-runs/<job id>/annotations
```

`ios-ci` annotates failing XCTest cases with their assertions, and the size-test step annotates the
failing command. `publish-maphero.sh --watch` prints the failure annotations for you.

**The unauthenticated API allows 60 requests an hour.** A 403 body parses as JSON perfectly well, so
a naive poller reads "rate limited" as "not finished yet" and spins. The script checks
`x-ratelimit-remaining` and parks until the window resets; it spends one request every 150s.

---

## Where previous releases came from

| Version | Built by |
|---|---|
| 0.0.1 – 1.2.1 | the one-job workflow on `main` (`ios-ci.yml` there, not the one on release branches) |
| 1.3.0, 1.3.1 | **by hand on a Mac.** No workflow run exists for either; the only runs that week are `typecheck-scripts` |
| 1.3.2 onward | `maphero-ios-release.yml`, by pushing a bare version tag |

`main`'s workflow still hardcodes `VERSION: 1.2.1` and triggers on `workflow_run` from
`clear_cache`, so it would rebuild **`main`** — 1.2.1 code — not a release branch. That is why the
release workflow now lives on the release branch and reads the version from the file.

---

## Not automated

- **CocoaPods.** `MapHero.podspec` is here and `ios-release-cocoapods.yml` is `workflow_dispatch`
  only. Nothing in this path publishes a pod.
- **`platform/ios/CHANGELOG.md`.** Worth updating, but nothing reads it: unlike upstream's
  pipeline, this release flow does not extract release notes from it.
- **dSYM distribution.** The dSYM zip is attached to the release. Nothing uploads it to a crash
  reporter.

## Known wart

`platform/ios/MapHero.xcframework` is **committed to this repository** — 269 files including two
Mach-O binaries, added alongside tag 1.3.0. It is a build output under version control. The release
workflow does not unzip anything into the working tree, so it cannot be shadowed by that copy, but
`ios-ci`'s size-test step *was* being shadowed by it: `unzip` prompted, read EOF on a runner,
declined to overwrite, and the step then measured the committed 1.3.0-era binary instead of the one
just built. Deleting it is a separate decision — something may reference the path.

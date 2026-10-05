#!/usr/bin/env bash
#
# Publish the MapHero iOS SDK.
#
# The build runs on CI, not here: this script does the parts that must be done from a clone --
# bump the version, check the preconditions that have actually broken releases before, push the
# tag that triggers the build -- then waits for it and prints the one line you paste into
# idealprojects/maphero-ios to make the new version installable.
#
# Usage:
#   ./publish-maphero.sh [VERSION] [options]
#
#   VERSION         Optional. Written to platform/ios/VERSION before tagging
#                   (e.g. ./publish-maphero.sh 1.3.3). If omitted, the current
#                   contents of the VERSION file are used.
#
#   --watch         After pushing the tag, wait for the CI run, then verify the
#                   published asset and print the Package.swift block.
#   --verify-only   Do not build or tag anything. Verify the release that already
#                   exists for VERSION and print its Package.swift block.
#   --dry-run       Say what would happen. Touches nothing local or remote.
#   --yes           Do not ask for confirmation before pushing.
#
# Requirements:
#   - push access to idealprojects/maphero-native (SSH is what this uses)
#   - curl, git. swift (for compute-checksum) or shasum as a fallback.
#   - NO GitHub API token: everything this reads is public.
#
# What it does NOT do:
#   - build locally. The XCFramework is built by .github/workflows/maphero-ios-release.yml on a
#     macos-15 runner, because this codebase cannot be built on every developer's Mac (see
#     PUBLISHING-MAPHERO.md, "Why the build is not local").
#   - publish to CocoaPods. MapHero.podspec exists but nothing has published through it.
#   - touch idealprojects/maphero-ios. It prints the change; you commit it there.
#
set -euo pipefail

IOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # platform/ios
REPO_ROOT="$(cd "$IOS_DIR/../.." && pwd)"
cd "$REPO_ROOT"

GITHUB_REPO="idealprojects/maphero-native"
ASSET_NAME="MapHero_ios_device.framework.zip"
RELEASE_WORKFLOW=".github/workflows/maphero-ios-release.yml"
SPM_REPO="idealprojects/maphero-ios"

# --- output ------------------------------------------------------------------
step() { printf '\033[1m\033[36m>> %s\033[0m\n' "$*"; }
warn() { printf '\033[1m\033[33m!! %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1m\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# --- arguments ---------------------------------------------------------------
VERSION_ARG=""
WATCH=0
VERIFY_ONLY=0
DRY_RUN=0
ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --watch)       WATCH=1 ;;
    --verify-only) VERIFY_ONLY=1 ;;
    --dry-run)     DRY_RUN=1 ;;
    --yes|-y)      ASSUME_YES=1 ;;
    -h|--help)     # the header comment, up to the first line that is not a comment
                   awk 'NR>1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*)            die "unknown option: $1" ;;
    *)             [ -z "$VERSION_ARG" ] || die "version given twice: $VERSION_ARG and $1"
                   VERSION_ARG="$1" ;;
  esac
  shift
done

confirm() {
  [ "$ASSUME_YES" = "1" ] && return 0
  printf '\033[1m%s\033[0m [y/N] ' "$1"
  local reply=""
  read -r reply </dev/tty || die "no terminal to confirm on; re-run with --yes if you mean it"
  case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) die "aborted" ;; esac
}

run() { # echo and execute, or just echo under --dry-run
  if [ "$DRY_RUN" = "1" ]; then printf '   would run: %s\n' "$*"; else "$@"; fi
}

# --- the GitHub API, unauthenticated ----------------------------------------
# 60 requests/hour, and the body of a 403 parses as JSON perfectly well -- which is how a poller
# ends up reading "rate limited" as "not finished yet" and spinning for an hour. So check the
# headers, and park until the window resets rather than guessing.
API_HEADERS="$(mktemp)"
trap 'rm -f "$API_HEADERS"' EXIT

api() {
  local url="$1" body code remaining reset wait
  body="$(curl -sS -D "$API_HEADERS" -H 'Accept: application/vnd.github+json' "$url")"
  code="$(awk 'NR==1{print $2}' "$API_HEADERS")"
  remaining="$(awk 'tolower($1)=="x-ratelimit-remaining:"{gsub(/\r/,"",$2); print $2}' "$API_HEADERS")"
  reset="$(awk 'tolower($1)=="x-ratelimit-reset:"{gsub(/\r/,"",$2); print $2}' "$API_HEADERS")"
  if [ "$code" = "403" ] || [ "${remaining:-1}" = "0" ]; then
    wait=$(( ${reset:-0} - $(date +%s) + 15 ))
    [ "$wait" -lt 15 ] && wait=15
    warn "GitHub API rate limit reached (60/hour, unauthenticated). Waiting ${wait}s for the window to reset."
    sleep "$wait"
    return 1
  fi
  [ "$code" = "200" ] || { warn "GitHub API returned HTTP $code for $url"; return 1; }
  printf '%s' "$body"
}

# --- version -----------------------------------------------------------------
VERSION="${VERSION_ARG:-$(tr -d '[:space:]' < "$IOS_DIR/VERSION")}"

# Validated BEFORE the file is written: the release workflow triggers on these tag shapes and no
# others, so a version it cannot match would push a tag that quietly builds nothing -- and writing
# first would leave an invalid version in VERSION on the way out.
case "$VERSION" in
  [0-9]*.[0-9]*.[0-9]*) : ;;
  *) die "version '$VERSION' is not X.Y.Z (optionally X.Y.Z-suffix); the release workflow only triggers on those tags" ;;
esac

if [ -n "$VERSION_ARG" ] && [ "$VERIFY_ONLY" = "0" ]; then
  if [ "$DRY_RUN" = "1" ]; then
    printf '   would write %s to platform/ios/VERSION\n' "$VERSION_ARG"
  else
    printf '%s\n' "$VERSION_ARG" > "$IOS_DIR/VERSION"
  fi
fi

# --- verify an existing release ---------------------------------------------
# Downloads what the world will download, and computes the checksum from that file rather than
# trusting what the release notes say.
verify_release() {
  local version="$1" url tmp checksum
  url="https://github.com/$GITHUB_REPO/releases/download/$version/$ASSET_NAME"
  step "Verifying the published asset for $version"
  printf '   %s\n' "$url"
  tmp="$(mktemp -d)"
  if ! curl -fsSL "$url" -o "$tmp/$ASSET_NAME"; then
    rm -rf "$tmp"
    die "could not download the asset. Is the release published (not a draft) and is the tag '$version'?"
  fi
  printf '   downloaded %s bytes\n' "$(wc -c < "$tmp/$ASSET_NAME" | tr -d ' ')"
  # A zip that is not a zip -- an HTML error page, say -- would otherwise be checksummed happily.
  unzip -qt "$tmp/$ASSET_NAME" >/dev/null 2>&1 || { rm -rf "$tmp"; die "the downloaded asset is not a valid zip"; }
  if command -v swift >/dev/null 2>&1; then
    checksum="$(swift package compute-checksum "$tmp/$ASSET_NAME")"
  else
    warn "swift not found; using shasum -a 256, which is the same value"
    checksum="$(shasum -a 256 "$tmp/$ASSET_NAME" | cut -d' ' -f1)"
  fi
  rm -rf "$tmp"

  printf '\n'
  step "Paste into Package.swift in $SPM_REPO"
  cat <<SPM
        .binaryTarget(
            name: "MapHero",
            url: "$url",
            checksum: "$checksum")
SPM
  printf '\n   Then commit it there. Nothing consumes %s until that file points at it.\n\n' "$version"
}

if [ "$VERIFY_ONLY" = "1" ]; then
  verify_release "$VERSION"
  exit 0
fi

# --- preconditions -----------------------------------------------------------
step "Checking preconditions for $VERSION"

command -v git >/dev/null 2>&1 || die "git is not installed"
command -v curl >/dev/null 2>&1 || die "curl is not installed"

# Which remote is this fork? Not necessarily "origin": in the working clone, "origin" is
# maplibre/maplibre-native upstream and the fork is "maphero".
REMOTE=""
for candidate in $(git remote); do
  case "$(git remote get-url "$candidate")" in
    *"$GITHUB_REPO"*) REMOTE="$candidate"; break ;;
  esac
done
[ -n "$REMOTE" ] || die "no git remote points at $GITHUB_REPO. Add one: git remote add maphero git@github.com:$GITHUB_REPO.git"
printf '   remote:  %s (%s)\n' "$REMOTE" "$(git remote get-url "$REMOTE")"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT="$(git rev-parse --short=11 HEAD)"
printf '   branch:  %s at %s\n' "$BRANCH" "$COMMIT"

# A tag build runs the workflow file from the TAGGED COMMIT. If it is not there, the tag lands and
# nothing happens -- no failure, no run, just silence.
[ -f "$RELEASE_WORKFLOW" ] || die "$RELEASE_WORKFLOW is missing from this commit. A tag build runs the workflow from the tagged commit, so tagging now would build nothing."
printf '   workflow: %s present\n' "$RELEASE_WORKFLOW"

# The workflow refuses a tag that disagrees with the file; fail here instead, where it is cheap.
FILE_VERSION="$(tr -d '[:space:]' < "$IOS_DIR/VERSION")"
if [ "$DRY_RUN" = "1" ] && [ -n "$VERSION_ARG" ]; then
  # --dry-run did not write the file, so compare against what it would have written.
  printf '   VERSION: %s (file still says %s; --dry-run does not write it)\n' "$VERSION" "$FILE_VERSION"
else
  [ "$FILE_VERSION" = "$VERSION" ] || die "platform/ios/VERSION says '$FILE_VERSION' but you are releasing '$VERSION'. Pass the version as an argument to bump the file."
  printf '   VERSION: %s\n' "$FILE_VERSION"
fi

# Releases are effectively permanent once consumers have fetched them.
if git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
  die "tag $VERSION already exists locally. Pick a new version; do not move a released tag."
fi
if git ls-remote --exit-code --tags "$REMOTE" "refs/tags/$VERSION" >/dev/null 2>&1; then
  die "tag $VERSION already exists on $REMOTE. Pick a new version; do not move a released tag."
fi
printf '   tag:     %s is free\n' "$VERSION"

DIRTY="$(git status --porcelain)"
if [ -n "$DIRTY" ]; then
  # The VERSION bump itself is expected; anything else means the tag would not describe the build.
  OTHER="$(printf '%s\n' "$DIRTY" | grep -v 'platform/ios/VERSION$' || true)"
  if [ -n "$OTHER" ]; then
    printf '%s\n' "$OTHER" | sed 's/^/     /'
    die "the working tree has changes other than platform/ios/VERSION. Commit or stash them: the tag must describe what was built."
  fi
fi

# --- commit the bump, if there is one ---------------------------------------
if ! git diff --quiet -- "$IOS_DIR/VERSION" 2>/dev/null; then
  step "Committing the version bump"
  run git add "platform/ios/VERSION"
  run git commit -m "iOS $VERSION"
  confirm "Push $BRANCH to $REMOTE?"
  run git push "$REMOTE" "HEAD:$BRANCH"
  COMMIT="$(git rev-parse --short=11 HEAD)"
fi

# --- tag and push ------------------------------------------------------------
printf '\n'
step "Ready to release"
cat <<SUMMARY
   version:  $VERSION
   commit:   $COMMIT  ($BRANCH)
   builds:   //platform/ios:MapHero.dynamic, opt, on macos-15
   publishes: https://github.com/$GITHUB_REPO/releases/tag/$VERSION
              asset $ASSET_NAME

   This release is public and immediate -- not a draft.
SUMMARY
printf '\n'
confirm "Push tag $VERSION and start the release build?"

run git tag "$VERSION" "$(git rev-parse HEAD)"
run git push "$REMOTE" "$VERSION"

if [ "$DRY_RUN" = "1" ]; then
  step "Dry run finished. Nothing was changed."
  exit 0
fi

step "Tag pushed. The build takes roughly 1-2 hours (opt build with thin_lto, cold bazel cache)."
printf '   https://github.com/%s/actions/workflows/maphero-ios-release.yml\n' "$GITHUB_REPO"

if [ "$WATCH" = "0" ]; then
  printf '\n   When it finishes:  %s --verify-only %s\n\n' "./platform/ios/publish-maphero.sh" "$VERSION"
  exit 0
fi

# --- watch -------------------------------------------------------------------
step "Waiting for the run (one API request every 150s, to stay inside the unauthenticated limit)"
RUN_ID=""
for _ in $(seq 1 20); do
  runs="$(api "https://api.github.com/repos/$GITHUB_REPO/actions/runs?per_page=20")" || continue
  RUN_ID="$(printf '%s' "$runs" | python3 -c '
import json,sys
want=sys.argv[1]
for r in json.load(sys.stdin).get("workflow_runs",[]):
    if r["name"]=="maphero-ios-release" and r["head_branch"]==want:
        print(r["id"]); break
' "$VERSION" 2>/dev/null || true)"
  [ -n "$RUN_ID" ] && break
  sleep 15
done
[ -n "$RUN_ID" ] || die "no maphero-ios-release run appeared for tag $VERSION. Check the Actions tab."
printf '   run: https://github.com/%s/actions/runs/%s\n' "$GITHUB_REPO" "$RUN_ID"

for i in $(seq 1 90); do
  jobs="$(api "https://api.github.com/repos/$GITHUB_REPO/actions/runs/$RUN_ID/jobs")" || continue
  line="$(printf '%s' "$jobs" | python3 -c '
import json,sys
for j in json.load(sys.stdin).get("jobs",[]):
    if j["name"]=="release":
        print(j["id"], j["status"], j["conclusion"], sep="|"); break
' 2>/dev/null || true)"
  status="$(printf '%s' "$line" | cut -d'|' -f2)"
  conclusion="$(printf '%s' "$line" | cut -d'|' -f3)"
  if [ "$status" = "completed" ]; then
    if [ "$conclusion" = "success" ]; then
      step "Build succeeded"
      verify_release "$VERSION"
      exit 0
    fi
    warn "the release job finished as '$conclusion'"
    # The job log needs admin rights on the repository; annotations do not.
    api "https://api.github.com/repos/$GITHUB_REPO/check-runs/$(printf '%s' "$line" | cut -d'|' -f1)/annotations" \
      | python3 -c '
import json,sys
try: a=json.load(sys.stdin)
except Exception: sys.exit()
for x in a:
    if x.get("annotation_level")=="failure": print("   ", x.get("title") or "", x["message"])
' || true
    die "release build failed. See https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID"
  fi
  printf '   %s... (%s)\n' "${status:-queued}" "$(date +%H:%M)"
  sleep 150
done
die "gave up waiting. The run may still be going: https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID"

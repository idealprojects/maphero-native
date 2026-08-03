#!/usr/bin/env bash
#
# Publish io.maphero:android-sdk to Maven Central (Sonatype Central Portal).
#
# Usage:
#   ./publish-maphero.sh [VERSION]
#
#   VERSION   Optional. If given, it is written to platform/android/VERSION
#             before publishing (e.g. ./publish-maphero.sh 1.1.1).
#             If omitted, the current contents of the VERSION file are used.
#
# Requirements (credentials — never commit these):
#   Put these in ~/.gradle/gradle.properties  (or export as ORG_GRADLE_PROJECT_* env vars):
#     mavenCentralUsername=<Central Portal user-token username>
#     mavenCentralPassword=<Central Portal user-token password>
#     signingInMemoryKey=<ASCII-armored GPG private key, newlines as \n>
#     signingInMemoryKeyPassword=<GPG key passphrase>
#   Generate the Portal token at: https://central.sonatype.com  -> Account -> Generate User Token
#   The account must own the verified namespace  io.maphero .
#
set -euo pipefail

# --- locations ---------------------------------------------------------------
ANDROID_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # platform/android
cd "$ANDROID_DIR"

# --- Android SDK -------------------------------------------------------------
# Point at the real SDK root (NOT the platform-tools subdir).
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
if [ ! -d "$ANDROID_HOME/platforms" ]; then
  echo "ERROR: ANDROID_HOME does not look like an SDK root: $ANDROID_HOME" >&2
  exit 1
fi

# --- version -----------------------------------------------------------------
if [ "${1:-}" != "" ]; then
  echo "$1" > VERSION
fi
VERSION="$(tr -d '[:space:]' < VERSION)"
echo ">> Publishing io.maphero:android-sdk:${VERSION}"

# --- credential check --------------------------------------------------------
GP="$HOME/.gradle/gradle.properties"
have_prop() { grep -q "^$1=" "$GP" 2>/dev/null || [ -n "${!2:-}" ]; }
missing=0
have_prop mavenCentralUsername       ORG_GRADLE_PROJECT_mavenCentralUsername       || { echo "  missing: mavenCentralUsername";       missing=1; }
have_prop mavenCentralPassword       ORG_GRADLE_PROJECT_mavenCentralPassword       || { echo "  missing: mavenCentralPassword";       missing=1; }
have_prop signingInMemoryKey         ORG_GRADLE_PROJECT_signingInMemoryKey         || { echo "  missing: signingInMemoryKey";         missing=1; }
have_prop signingInMemoryKeyPassword ORG_GRADLE_PROJECT_signingInMemoryKeyPassword || { echo "  missing: signingInMemoryKeyPassword"; missing=1; }
if [ "$missing" = "1" ]; then
  echo "ERROR: publish credentials not found (see header of this script)." >&2
  exit 1
fi

# --- 1) local sanity check: sign + publish to ~/.m2 (fast, one ABI) ----------
echo ">> Sanity check: signing + local publish (arm64-v8a)…"
./gradlew :MapHeroAndroid:publishDefaultreleasePublicationToMavenLocal \
  -Pmaplibre.abis=arm64-v8a --no-configuration-cache
ASC=~/.m2/repository/io/maphero/android-sdk/${VERSION}/android-sdk-${VERSION}.aar.asc
[ -f "$ASC" ] || { echo "ERROR: signature not produced ($ASC) — check the signing key." >&2; exit 1; }
echo ">> Signature OK."

# --- 2) real release: all ABIs -> Central Portal -> auto-release -------------
echo ">> Building all ABIs and publishing to Maven Central (this takes ~15-25 min)…"
./gradlew :MapHeroAndroid:publishAndReleaseToMavenCentral --no-configuration-cache

# --- 3) wait until it is live on Maven Central -------------------------------
echo ">> Uploaded & release triggered. Waiting for propagation to repo1.maven.org…"
AAR_URL="https://repo1.maven.org/maven2/io/maphero/android-sdk/${VERSION}/android-sdk-${VERSION}.aar"
for _ in $(seq 1 30); do        # up to ~45 min
  code="$(curl -s -o /dev/null -w '%{http_code}' "$AAR_URL")"
  echo "   $(date +%H:%M:%S)  $AAR_URL -> $code"
  if [ "$code" = "200" ]; then
    echo ">> LIVE: io.maphero:android-sdk:${VERSION} is on Maven Central."
    echo "   implementation(\"io.maphero:android-sdk:${VERSION}\")"
    exit 0
  fi
  sleep 90
done
echo ">> Upload succeeded but not yet visible after ~45 min."
echo "   Check central.sonatype.com -> Deployments for the status."

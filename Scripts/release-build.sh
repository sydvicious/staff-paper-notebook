#!/bin/bash
#
# Copyright ©2026 Syd Polk. All Rights Reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Makes a release. **main always carries the version of the next release**, so
# from a clean main this:
#
#   1. runs every test, with Scripts/run-tests-release.sh, and goes no further
#      if any of them fails;
#   2. builds the Release configuration for iOS, unsigned, to be sure it
#      builds and carries the version the tag will name;
#   3. tags the commit it built release-<version>-build-<build>.
#
# **No DMG and no upload.** The app is for iPhone and iPad, and App Store
# Connect is not set up for it yet, so a release is the tag. An .ipa, when one
# is wanted, is archived by hand in Xcode. When App Store Connect is ready, the
# archive, export and upload go between steps 2 and 3.
#
# **It does not bump.** A release may take several candidates before one ships,
# so bump-version.sh stays separate: run it with no options for the next
# candidate, which needs a new build number (this refuses a tag already taken),
# and with --minor once a release has shipped, so main moves on to the next one.
#
# Nothing is pushed. It never starts from a dirty repo.
#
# Syd's to run, not an agent's: it tags.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO/StaffPaperNotebook.xcodeproj"
BUILD_DIR="${SPN_BUILD_ROOT:-$HOME/Library/Developer/Xcode/DerivedData/StaffPaperNotebook-scripts}/release"
TESTS=1

usage() {
    cat <<'HELPTEXT'
Releases Staff Paper Notebook: every test, a Release build, and a tag on the
commit it was built from. It does not bump; bump-version.sh does that.

USAGE
  ./Scripts/release-build.sh [options]

OPTIONS
  --output <dir>   Where to build. Default:
                   ~/Library/Developer/Xcode/DerivedData/StaffPaperNotebook-scripts/release
                   or $SPN_BUILD_ROOT/release. Never the repository.
  --no-tests       Release without running the tests first. For a commit whose
                   tests have just been run by hand, with
                   Scripts/run-tests-release.sh.
  -h, --help       This.

NEEDS, EVERY RELEASE
  A clean main (no changes, and no untracked files that are not ignored), and a
  "## <version>" heading in CHANGELOG.md for the release. Every test passing:
  Scripts/run-tests-release.sh is run first, and --help there says what it
  needs, its simulators among them. Its logs are in <output>/tests.

RESULT
  The tag release-<version>-build-<build>. The build products stay in
  <output>. Nothing is pushed, and nothing is uploaded.

AFTERWARDS
  Another candidate:          ./Scripts/bump-version.sh
  It shipped:                 ./Scripts/bump-version.sh --minor
HELPTEXT
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output) BUILD_DIR="$2"; shift 2 ;;
        --no-tests) TESTS=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$BUILD_DIR" in
    "$REPO"|"$REPO"/*) echo "refusing to build inside the repository: $BUILD_DIR" >&2; exit 2 ;;
esac

git() { command git -C "$REPO" "$@"; }
read_setting() { sed -n "s/^$1 = //p" "$REPO/Version.xcconfig" | tr -d '[:space:]'; }

# **Never from a dirty repo**: what is tagged has to be a commit anyone can
# check out. Untracked files count too, because Xcode compiles whatever is in a
# synchronized folder whether git knows about it or not. Ignored files do not.
if [[ -n "$(git status --porcelain)" ]]; then
    echo "the repo is dirty; commit or remove these first:" >&2
    git status --short >&2
    exit 1
fi

# Everything else that would stop a release, found before anything is built.
# The tag belongs on main, and CHANGELOG.md should say what is in it.
VERSION="$(read_setting MARKETING_VERSION)"
BUILD="$(read_setting CURRENT_PROJECT_VERSION)"
TAG="release-$VERSION-build-$BUILD"
COMMIT="$(git rev-parse HEAD)"
problems=()
[[ "$(git branch --show-current)" == "main" ]] || problems+=("not on main: $(git branch --show-current)")
git show-ref --verify --quiet "refs/tags/$TAG" && problems+=("tag $TAG already exists")
grep -qx "## $VERSION" "$REPO/CHANGELOG.md" || problems+=("no \"## $VERSION\" heading in CHANGELOG.md")
if (( ${#problems[@]} > 0 )); then
    echo "cannot release $VERSION ($BUILD):" >&2
    printf '  %s\n' "${problems[@]}" >&2
    exit 1
fi

# **Every test first.** Nothing is tagged from a commit with a test failing, or
# with tests that could not be run. After the checks above, so that a release
# that could not be made anyway does not wait for them.
if [[ $TESTS -eq 1 ]]; then
    echo "==> Testing"
    "$REPO/Scripts/run-tests-release.sh" --output "$BUILD_DIR/tests" \
        || { echo "the tests did not pass; nothing has been built or tagged" >&2; exit 1; }
else
    echo "==> Not testing: --no-tests" >&2
fi

# The tests run the Debug build. This is the configuration an archive is made
# from, built unsigned so no certificate or profile is needed.
echo "==> Building Release"
DERIVED="$BUILD_DIR/DerivedData"
xcodebuild -project "$PROJECT" -scheme StaffPaperNotebook -configuration Release \
    -destination "generic/platform=iOS" -derivedDataPath "$DERIVED" \
    CODE_SIGNING_ALLOWED=NO -quiet build
APP="$DERIVED/Build/Products/Release-iphoneos/StaffPaperNotebook.app"

# **From the app, not from Version.xcconfig**, so the tag can never name a
# version other than the one built.
BUILT_VERSION="$(plutil -extract CFBundleShortVersionString raw -o - "$APP/Info.plist")"
BUILT_BUILD="$(plutil -extract CFBundleVersion raw -o - "$APP/Info.plist")"
if [[ "$TAG" != "release-$BUILT_VERSION-build-$BUILT_BUILD" ]]; then
    echo "the app is $BUILT_VERSION ($BUILT_BUILD), but Version.xcconfig named $TAG" >&2
    exit 1
fi

# The tag goes on the commit the build started from. Advice goes to stderr, so
# the last line on stdout is the tag.
echo "==> Tagging $TAG"
git tag -a "$TAG" "$COMMIT" -m "Staff Paper Notebook $VERSION ($BUILD)"
echo "the tag goes to origin with the next bump, or now: git push origin $TAG" >&2
echo "another candidate: Scripts/bump-version.sh" >&2
echo "it shipped:        Scripts/bump-version.sh --minor" >&2
echo "$TAG"

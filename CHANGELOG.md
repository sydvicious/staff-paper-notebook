<!-- Copyright @2026 Syd Polk. All Rights Reserved -->
<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Changelog

## 0.1

- The Xcode project, for iPhone and iPad on iOS 27 and later, in Swift 6 with complete strict concurrency and the Main Actor as the default isolation.
- Versioning and releases: `Version.xcconfig`, `Scripts/bump-version.sh`, `Scripts/run-tests-release.sh`, and `Scripts/release-build.sh` with its `Make Release` target. A release runs every test and tags; it builds no DMG and uploads nothing.

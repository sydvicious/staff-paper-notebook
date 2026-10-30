<!-- Copyright @2026 Syd Polk. All Rights Reserved -->
<!-- SPDX-License-Identifier: BSD-3-Clause -->
# General instructions

## The project

* Staff Paper Notebook is a SwiftUI app for iPhone and iPad, with a deployment target of iOS 27. It is not built for the Mac, Catalyst or Vision Pro.
* Swift 6 language mode, complete strict concurrency, and the Main Actor as the default isolation, set at the project level so every target shares them.
* The app's code is in `StaffPaperNotebook/`, and its tests, in Swift Testing, are in `StaffPaperNotebookTests/`. Both are synchronized folders: Xcode compiles whatever is in them, tracked by git or not.

## Plans

* `plans/PLAN.md` is the master plan. A plan for a single feature goes beside it in `plans/`, named for what it plans.

## Changelog

* `CHANGELOG.md` records shipped or notable changes, in this format:
  - One top-level entry per release, as a `##` heading naming the version (`## 0.2`), newest first. No dates.
  - Whenever you add to CHANGELOG.md, check for a `## <version>` heading for the current `MARKETING_VERSION` in `Version.xcconfig`, and add it at the top, above the previous release, if it is missing. New bullets go at the top of that release's section. `Scripts/release-build.sh` refuses to release without the heading, so the heading and its content are built up as the work happens, not at release time. For Claude the heading is automatic: a global hook (`~/.claude/hooks/changelog-version-heading.sh`) adds it whenever Claude edits the file.
  - Bullets describe user-visible behavior changes, platform updates, or notable implementation changes.
  - Keep bullets terse. Prefix with the platform — `(iOS)`, `(iPadOS)` — only when the change does not apply to both; omit the prefix when it does. Use Apple's capitalization: `iOS`, `iPadOS`.

## Releases

* `Scripts/release-build.sh`, `Scripts/bump-version.sh` and the `Make Release` scheme are Syd's to run: they tag, and the bump also commits and pushes. An agent may run `--help`, and `bump-version.sh --dry-run`.
* A release runs every test, builds the Release configuration, and tags. It builds no DMG and uploads nothing, since App Store Connect is not set up for the app yet.
* `Scripts/run-tests-release.sh` runs every test on Claude iPhone and Claude iPad, on iOS 27. It changes nothing in the repository, and an agent may run it. Set `SPN_BUILD_ROOT` to a scratchpad folder so nothing is built into Syd's DerivedData.

## Copyright

* If a new source or text file is generated, please add `Copyright @{{year}} Syd Polk.`
* If you modify a source file without a copyright, please add the above notice.
* If you modify a source file with an existing notice, and the current year is different from the last year listed, add a comma and the current year, i.e., `Copyright @2026 Syd Polk. All Rights Reserved` becomes `Copyright @2026, 2027 Syd Polk. All Rights Reserved`. It's explicitly ok to skip years, i.e., `2026, 2028`
* Every notice is followed by an SPDX line naming the project's license, so a file read on its own is not mistaken for proprietary code. This project is BSD 3-Clause; "All Rights Reserved" is part of the standard BSD template and does not contradict it, but on its own it reads as a reservation of everything.

  Swift, and `.xcconfig` files:

  ```swift
  //
  // Copyright ©2026 Syd Polk. All Rights Reserved.
  // SPDX-License-Identifier: BSD-3-Clause
  //
  ```

  Shell scripts:

  ```bash
  #
  # Copyright ©2026 Syd Polk. All Rights Reserved.
  # SPDX-License-Identifier: BSD-3-Clause
  #
  ```

  Markdown:

  ```markdown
  <!-- Copyright @2026 Syd Polk. All Rights Reserved -->
  <!-- SPDX-License-Identifier: BSD-3-Clause -->
  ```

* Exempt: `LICENSE`, which is the license itself; JSON files, such as the asset catalog's, which have no comments; and the files Xcode writes: the project file, in either format (`project.pbxproj` or `project.xcproj`), and the schemes.

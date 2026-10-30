//
// Copyright ©2026 Syd Polk. All Rights Reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import Testing

/// The app's version and build number come from Version.xcconfig, which is the
/// base configuration of every target. The release script names its tag from
/// that file, so the app it tags has to say the same thing.
struct VersionTests {
    private let info = Bundle.main.infoDictionary ?? [:]

    @Test func versionIsTwoParts() throws {
        let version = try #require(info["CFBundleShortVersionString"] as? String)
        #expect(version.wholeMatch(of: /[0-9]+\.[0-9]+/) != nil, "\(version) is not x.y")
    }

    @Test func buildIsANumber() throws {
        let build = try #require(info["CFBundleVersion"] as? String)
        #expect(Int(build) != nil, "\(build) is not a number")
    }
}

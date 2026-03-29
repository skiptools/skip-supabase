// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import XCTest
import OSLog
import Foundation
@testable import SkipSupabaseAuth

let logger: Logger = Logger(subsystem: "SkipSupabaseAuth", category: "Tests")

@available(macOS 13, *)
final class SkipSupabaseAuthTests: XCTestCase {
    func testSkipSupabaseAuth() throws {
        logger.log("running testSkipSupabaseAuth")
    }
}

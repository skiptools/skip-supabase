// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
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

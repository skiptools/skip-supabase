// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
import OSLog
import Foundation
@testable import SkipSupabaseFunctions

let logger: Logger = Logger(subsystem: "SkipSupabaseFunctions", category: "Tests")

@available(macOS 13, *)
final class SkipSupabaseFunctionsTests: XCTestCase {
    func testSkipSupabaseFunctions() throws {
        logger.log("running testSkipSupabaseFunctions")
    }
}

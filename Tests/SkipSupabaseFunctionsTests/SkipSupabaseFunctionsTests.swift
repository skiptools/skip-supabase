// SPDX-License-Identifier: MPL-2.0
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

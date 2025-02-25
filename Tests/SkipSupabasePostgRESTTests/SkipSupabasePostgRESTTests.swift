// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
import OSLog
import Foundation
@testable import SkipSupabasePostgREST

let logger: Logger = Logger(subsystem: "SkipSupabasePostgREST", category: "Tests")

@available(macOS 13, *)
final class SkipSupabasePostgRESTTests: XCTestCase {
    func testSkipSupabasePostgREST() throws {
        logger.log("running testSkipSupabasePostgREST")
    }
}

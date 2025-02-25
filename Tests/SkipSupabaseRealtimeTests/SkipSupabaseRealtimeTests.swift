// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
import OSLog
import Foundation
@testable import SkipSupabaseRealtime

let logger: Logger = Logger(subsystem: "SkipSupabaseRealtime", category: "Tests")

@available(macOS 13, *)
final class SkipSupabaseRealtimeTests: XCTestCase {
    func testSkipSupabaseRealtime() throws {
        logger.log("running testSkipSupabaseRealtime")
    }
}

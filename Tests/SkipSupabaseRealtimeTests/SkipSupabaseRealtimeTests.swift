// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
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

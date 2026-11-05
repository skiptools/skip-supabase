// Copyright 2024–2026 Skip
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

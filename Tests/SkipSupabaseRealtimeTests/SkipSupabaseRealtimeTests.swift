// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

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

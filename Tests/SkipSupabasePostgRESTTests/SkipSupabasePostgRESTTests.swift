// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

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

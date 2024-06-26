// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

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

// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
@testable import SkipSupabaseStorage

let logger: Logger = Logger(subsystem: "SkipSupabaseStorage", category: "Tests")

@available(macOS 13, *)
final class SkipSupabaseStorageTests: XCTestCase {
    func testSkipSupabaseStorage() throws {
        logger.log("running testSkipSupabaseStorage")
    }
}

// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
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

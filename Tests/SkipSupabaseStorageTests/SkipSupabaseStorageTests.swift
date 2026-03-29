// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
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

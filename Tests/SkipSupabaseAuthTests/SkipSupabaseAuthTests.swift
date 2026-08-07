// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import XCTest
import OSLog
import Foundation
@testable import SkipSupabaseAuth

let logger: Logger = Logger(subsystem: "SkipSupabaseAuth", category: "Tests")

@available(macOS 13, *)
final class SkipSupabaseAuthTests: XCTestCase {
    func testSkipSupabaseAuth() throws {
        logger.log("running testSkipSupabaseAuth")
    }

    func testSignInWithOAuthNoCrash() async throws {
        logger.log("running testSignInWithOAuthNoCrash")

        // Construct a minimal auth client using the public API. This test only ensures
        // that calling signInWithOAuth does not crash and that the completion handler
        // is invoked. It does not perform a real OAuth roundtrip.
        let client = SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: "test")
        let ac: AuthClient = client.auth

        let exp = expectation(description: "oauth-completion")

        try await ac.signInWithOAuth(provider: .google, redirectTo: "https://example.com/callback", scopes: "profile", queryParams: [(name: "x", value: "y")]) { session in
            // We expect nil in unit tests; just ensure completion runs.
            XCTAssertNil(session)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
    }
}

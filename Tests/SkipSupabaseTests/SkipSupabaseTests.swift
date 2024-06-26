// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
@testable import SkipSupabase

let logger: Logger = Logger(subsystem: "SkipSupabase", category: "Tests")

@available(macOS 13, *)
final class SkipSupabaseTests: XCTestCase {
    func testSkipSupabase() async throws {
        logger.log("running testSkipSupabase")
        #if !SKIP
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://zncizygaxuzzvxnsfdvp.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpuY2l6eWdheHV6enZ4bnNmZHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDc4NjE1NDksImV4cCI6MjAyMzQzNzU0OX0.yoFteItT4FVu_kbMuMnQCzE8YYU5jEVWLU7NDBY94-E"
        )

        struct Country: Codable {
          let id: Int
          let name: String
        }

        // clear the countries table
        try await client
            .from("countries")
            .delete()
            .gte("id", value: 0)
            .execute()

        try await client
            .from("countries")
            .insert([
                Country(id: 1, name: "USA"),
                Country(id: 2, name: "France"),
                Country(id: 3, name: "Germany"),
            ])
            .execute()

        let countryCount = try await client
            .from("countries")
            .select(count: .exact)
            .execute()

        XCTAssertEqual(3, countryCount.count)

        let countries: [Country] = try await client
          .from("countries")
          .select()
          .order("id")
          .execute()
          .value

        XCTAssertEqual("USA", countries.first?.name)

        try await client
          .from("countries")
          .update(["name": "Australia"])
          .eq("id", value: 1)
          .execute()

        let countries2: [Country] = try await client
          .from("countries")
          .select()
          .order("id")
          .execute()
          .value

        XCTAssertEqual("Australia", countries2.first?.name)

        // clear the countries table
        try await client
            .from("countries")
            .delete()
            .gte("id", value: 0)
            .execute()

        #endif
    }
}

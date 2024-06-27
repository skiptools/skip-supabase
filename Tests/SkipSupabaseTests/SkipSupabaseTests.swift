// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
@testable import SkipSupabase

let logger: Logger = Logger(subsystem: "SkipSupabase", category: "Tests")

struct Country: Codable {
  let id: Int
  let name: String
}

@available(macOS 13, *)
final class SkipSupabaseTests: XCTestCase {
    func testSkipSupabase() async throws {
        logger.log("running testSkipSupabase")
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://zncizygaxuzzvxnsfdvp.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpuY2l6eWdheHV6enZ4bnNmZHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDc4NjE1NDksImV4cCI6MjAyMzQzNzU0OX0.yoFteItT4FVu_kbMuMnQCzE8YYU5jEVWLU7NDBY94-E"
        )

        // clear the countries table
        let cquery = client.from("countries")

        #if !SKIP

        try await cquery
            .delete()
            .gte("id", value: 0)
            .execute()

        // insert single
        try await client
            .from("countries")
            .insert(Country(id: 1, name: "USA"))
            .execute()

        // insert array
        try await client
            .from("countries")
            .insert([
                Country(id: 2, name: "France"),
                Country(id: 3, name: "Germany"),
            ])
            .execute()

        // count query
        let countryCount = try await client
            .from("countries")
            .select(count: .exact)
            .execute()

        XCTAssertEqual(3, countryCount.count)

        // query single row
        let countries: [Country] = try await client
          .from("countries")
          .select()
          .order("id")
          .limit(1)
          .execute()
          .value

        XCTAssertEqual("USA", countries.first?.name)

        // update
        try await client
          .from("countries")
          .update(["name": "Australia"])
          .eq("id", value: 1)
          .execute()

        // verify query
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

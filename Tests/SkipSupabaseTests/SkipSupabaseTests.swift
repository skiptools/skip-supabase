// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
@testable import SkipSupabase

let logger: Logger = Logger(subsystem: "SkipSupabase", category: "Tests")

struct Country: Codable {
    var id: Int
    var name: String
    var created: Date? = nil
    var gdp: Decimal? = nil
}


fileprivate let client = SupabaseClient(
    supabaseURL: URL(string: "https://zncizygaxuzzvxnsfdvp.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpuY2l6eWdheHV6enZ4bnNmZHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDc4NjE1NDksImV4cCI6MjAyMzQzNzU0OX0.yoFteItT4FVu_kbMuMnQCzE8YYU5jEVWLU7NDBY94-E"
)


final class SkipSupabaseTests: XCTestCase {
    func testSkipSupabaseAuth() async throws {

        #if SKIP
        //com.russhwolf.settings.Settings() // else: com.russhwolf.settings.NoArgKt.Settings(NoArg.kt:32)
        #endif

        let ac: AuthClient = client.auth
        XCTAssertNil(ac.currentSession)
        XCTAssertNil(ac.currentSession?.user.email)
        XCTAssertNil(ac.currentSession?.user.confirmationSentAt)
        XCTAssertNil(ac.currentSession?.user.createdAt)
        XCTAssertNil(ac.currentSession?.user.lastSignInAt)
        XCTAssertNil(ac.currentSession?.user.phone)
        XCTAssertNil(ac.currentSession?.user.role)
        XCTAssertNil(ac.currentSession?.user.updatedAt)

        do {
            try await ac.signIn(email: "", password: "")
            try await ac.signIn(email: "", password: "", captchaToken: "")
            try await ac.signIn(phone: "", password: "")
            try await ac.signIn(phone: "", password: "", captchaToken: "")
            try await ac.signInAnonymously()
            try await ac.signInAnonymously(captchaToken: "")
            //try await ac.signInAnonymously(data: ["key": .string("value")])

            //try await ac.signInWithSSO(domain: <#T##String#>, redirectTo: <#T##URL?#>, captchaToken: <#T##String?#>)
            //try await ac.signInWithOTP(phone: <#T##String#>, channel: <#T##MessagingChannel#>, shouldCreateUser: <#T##Bool#>, data: <#T##[String : AnyJSON]?#>, captchaToken: <#T##String?#>)
            //try await ac.signInWithOTP(email: <#T##String#>, redirectTo: <#T##URL?#>, shouldCreateUser: <#T##Bool#>, data: <#T##[String : AnyJSON]?#>, captchaToken: <#T##String?#>)
            //try await ac.signInWithOAuth(provider: <#T##Provider#>, redirectTo: <#T##URL?#>, scopes: <#T##String?#>, queryParams: <#T##[(name: String, value: String?)]#>, configure: <#T##(ASWebAuthenticationSession) -> Void##(ASWebAuthenticationSession) -> Void##(_ session: ASWebAuthenticationSession) -> Void#>)


            try await ac.signOut()
            try await ac.signOut(scope: .global)
            try await ac.signOut(scope: .local)
            try await ac.signOut(scope: .others)

            //let _: AsyncStream<(event: AuthChangeEvent, session: Session?)> = ac.authStateChanges

            XCTFail("signIn should have failed")
        } catch {
            // expected
        }
    }

    func testSkipSupabaseDatabase() async throws {
        logger.log("running testSkipSupabase")

        // clear the countries table
        // SKIP NOWARN
        let voidResponse: PostgrestResponse<Void> = try await client
            .from("countries")
            .delete()
            .gte("id", value: 0)
            .execute()
        let _ = voidResponse

        func assertCount(_ table: String, count: Int) async throws {
            // count query
            // SKIP NOWARN
            let countryCount0: PostgrestResponse<Void> = try await client
                .from(table)
                .select(count: CountOption.exact)
                .execute()
            XCTAssertEqual(count, countryCount0.count)
        }

        try await assertCount("countries", count: 0)

        let now = Date()

        @discardableResult func insert(country: Country) async throws -> Country? {
            // SKIP NOWARN
            let results: PostgrestResponse<[Country]> = try await client
                .from("countries")
                .insert(country, returning: PostgrestReturningOptions.representation)
                .execute(options: FetchOptions(head: false, count: CountOption.exact))
            return results.value.first
        }

        try await assertCount("countries", count: 0)
        let icountry = try await insert(country: Country(id: 1, name: "USA"))
        try await assertCount("countries", count: 1)

        var country1 = try XCTUnwrap(icountry)

        XCTAssertEqual(1, country1.id)
        let country1Created = try XCTUnwrap(country1.created)
        XCTAssertGreaterThanOrEqual(country1Created, now)

        try await insert(country: Country(id: 2, name: "France"))
        try await insert(country: Country(id: 3, name: "Germany"))
        try await assertCount("countries", count: 3)

        // count query
        // SKIP NOWARN
        let countryCount = try await client
            .from("countries")
            .select(count: .exact)
            .execute()

        XCTAssertEqual(3, countryCount.count)

        // query single row
        let countriesResp: PostgrestResponse<[Country]> = try await client
          .from("countries")
          .select()
          .order("id")
          .limit(1)
          .execute(options: FetchOptions(head: false, count: CountOption.exact))
        let countries = countriesResp.value

        //XCTAssertEqual(1, countriesResp.count)
        XCTAssertEqual("USA", countries.first?.name)

        // update
        country1.name = "Australia"
        country1.gdp = Decimal(123.456)

        // SKIP NOWARN
        try await client
          .from("countries")
          //.update(["name": "Australia"]) // java.lang.ClassCastException: class skip.lib.Tuple2 cannot be cast to class skip.lib.Encodable
          .update(country1)
          .eq("id", value: 1)
          .execute()

        // verify query
        let countries2Resp: PostgrestResponse<[Country]> = try await client
          .from("countries")
          .select()
          .order("id", ascending: false)
          .execute(options: FetchOptions(head: false, count: CountOption.exact))

        let countries2 = countries2Resp.value

        XCTAssertEqual("Australia", countries2.last?.name)

        @MainActor func assertQueryCount(_ count: Int, _ block: (PostgrestFilterBuilder) -> (PostgrestFilterBuilder)) async throws {
            let q: PostgrestFilterBuilder = block(client.from("countries").select())
            let response: PostgrestResponse<[Country]> = try await q.execute(options: FetchOptions(head: false, count: CountOption.exact))
            XCTAssertEqual(count, response.value.count, "value mismatch for \(q): \(count) vs. \(response.value.count)")
        }

        try await assertQueryCount(3, { $0 })
        try await assertQueryCount(1, { $0.eq("id", value: 1) })
        try await assertQueryCount(0, { $0.eq("id", value: 999) })
        try await assertQueryCount(1, { $0.eq("id", value: 1) })
        try await assertQueryCount(2, { $0.gt("id", value: 1) })
        try await assertQueryCount(3, { $0.gte("id", value: 1) })
        try await assertQueryCount(1, { $0.lt("id", value: 2) })
        try await assertQueryCount(3, { $0.lte("id", value: 3) })
        try await assertQueryCount(1, { $0.lte("name", value: "Australia") })
        try await assertQueryCount(3, { $0.gte("name", value: "Australia") })
        try await assertQueryCount(2, { $0.in("name", values: ["Germany", "France", "XXX"]) })
        try await assertQueryCount(1, { $0.gte("gdp", value: 123) })
        //try await assertQueryCount(0, { $0.contains("name", value: ["XXX"]) })
        //try await assertQueryCount(0, { $0.containedBy("name", value: ["XXX"]) })

        // clear the countries table
//        // SKIP NOWARN
//        try await client
//            .from("countries")
//            .delete()
//            .gte("id", value: 0)
//            .execute()
    }

    func testSkipSupabaseRPC() async throws {
        // SKIP NOWARN
        let rpc1: PostgrestResponse<Void> = try await client
            .rpc("rpc_test")
            .execute()

        XCTAssertEqual(rpc1.status, 200)
        XCTAssertEqual(String(data: rpc1.data, encoding: .utf8), "\"Hello Supabase RPC\"")

        let value1: Void = rpc1.value
        let _ = value1

//        let rpc2: Void = try await client
//            .rpc("rpc_test_params", params: Country(id: 2, name: "France"))
//            .execute()
//            .value
    }
    
    /* Created with:
        CREATE OR REPLACE FUNCTION public.rpc_test_with_param(testParam1 text, testParam2 text) returns text as $$
        select 'Hello Supabase RPC With Param: ' || testParam1 || testParam2;
        $$ LANGUAGE sql;
     */
    func testSkipSupabaseRPCWithParams() async throws {
        // SKIP NOWARN
        let rpc1: PostgrestResponse<Void> = try await client
            .rpc("rpc_test_with_param", params: [
                "testparam1": "testValue",
                "testparam2": "1"
            ])
            .execute()

        XCTAssertEqual(rpc1.status, 200)
        XCTAssertEqual(String(data: rpc1.data, encoding: .utf8), "\"Hello Supabase RPC With Param: testValue1\"")

        let value1: Void = rpc1.value
        let _ = value1
    }
}

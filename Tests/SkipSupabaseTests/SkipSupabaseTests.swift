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
        let voidResponse: PostgrestResponse<Void> = try await client
            .from("countries")
            .delete()
            .gte("id", value: 0)
            .execute()

        func assertCount(_ table: String, count: Int) async throws {
            // count query
            let countryCount0: PostgrestResponse<Void> = try await client
                .from(table)
                .select(count: CountOption.exact)
                .execute()
            XCTAssertEqual(count, countryCount0.count)
        }

        try await assertCount("countries", count: 0)

        // insert single
        let icountryResponse: PostgrestResponse<[Country]> = try await client
            .from("countries")
            .insert(Country(id: 1, name: "USA"), returning: PostgrestReturningOptions.representation)
            // .single() // TODO: handle single results
            .execute(options: FetchOptions(head: false, count: CountOption.exact))

        try await assertCount("countries", count: 1)

        let icountry: [Country] = icountryResponse.value
        XCTAssertEqual(1, icountry.first?.id)

        #if !SKIP

        // FIXME Kotlin: SkipSupabase.kt:900 testSkipModule(): java.lang.IllegalArgumentException: Element class kotlinx.serialization.json.JsonArray is not a JsonObject

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

    func testSkipSupabaseRPC() async throws {
        // SKIP NOWARN
        let rpc1: PostgrestResponse<Void> = try await client
            .rpc("rpc_test")
            .execute()

        XCTAssertEqual(rpc1.status, 200)
        XCTAssertEqual(String(data: rpc1.data, encoding: .utf8), "\"Hello Supabase RPC\"")

        let value1: Void = rpc1.value

//        let rpc2: Void = try await client
//            .rpc("rpc_test_params", params: Country(id: 2, name: "France"))
//            .execute()
//            .value
    }
    
    /* Created with:
      CREATE OR REPLACE FUNCTION public.rpc_test_with_param(testParam1 text, testParam2 text) returns text as $$
      BEGIN
        select 'Hello Supabase RPC With Param: ' || testParam1 || testParam2;
      END;
      $$ LANGUAGE plpgsql VOLATILE;
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

    }

}

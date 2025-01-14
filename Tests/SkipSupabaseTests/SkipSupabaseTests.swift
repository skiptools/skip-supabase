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

    func testSupabaseStorage() async throws {
        // create a random path
        let bucketName = "images"
        let fileName = "tiny-\(UUID().uuidString).png"
        let folder = "public"
        let path = folder + "/" + fileName
        let fileData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4z8AAAAMBAQD3A0FDAAAAAElFTkSuQmCC")!

        let storage: SupabaseStorageClient = client.storage

        let buckets = try await storage.listBuckets()

        let images: StorageFileApi = storage.from(bucketName)

        let response1: FileUploadResponse = try await images
            .upload(path, data: fileData, options: FileOptions(contentType: "image/png"))
        XCTAssertEqual(path, response1.path)
        XCTAssertEqual(bucketName + "/" + path, response1.fullPath)

        let topts = TransformOptions(width: 10, height: 10, resize: "fill", quality: 100, format: nil)

        let data = try await storage
            .from("images")
            .download(path: path)

        if false { // this block merely validates the presence of the transpiled API
            try await images.copy(from: path, to: "public/tiny-copy.png")
            let removed: [FileObject] = try await images.remove(paths: [path])
            let updated: FileUploadResponse = try await images.update(path, data: fileData, options: FileOptions(cacheControl: "", contentType: "image/png", upsert: true, duplex: nil, metadata: nil /*["x": AnyJSON(stringLiteral: "ABC")]*/, headers: ["HeaderA": "ValueA"]))
            let dopts = DestinationOptions(destinationBucket: "images2")
            try await images.move(from: path, to: "public/tiny-move.png", options: dopts)
            let downloaded: Data = try await images.download(path: path, options: topts)

            // Bucket API
            let bucket: Bucket = try await storage.getBucket("XYZ")
            try await storage.createBucket("XYZ", options: BucketOptions(public: true, fileSizeLimit: "1024", allowedMimeTypes: ["image/png"]))
            try await storage.updateBucket("XYZ", options: BucketOptions(public: true, fileSizeLimit: "1024", allowedMimeTypes: ["image/*"]))
            try await storage.emptyBucket("XYZ")
            try await storage.deleteBucket("XYZ")

            // Unsupported API
            #if !SKIP
            // needs: https://github.com/supabase-community/supabase-kt/pull/694
            let fileInfo: FileObjectV2 = try await images.info(path: path)
            let exists = try await images.exists(path: path)
            XCTAssertTrue(exists, "file did not exist at: \(path)")

            // Signed URL API
            let signedUploadURL: SignedUploadURL = try await images.createSignedUploadURL(path: path, options: CreateSignedUploadURLOptions(upsert: true))
            let signedUploadResponse: SignedURLUploadResponse = try await images.uploadToSignedURL(path, token: "ABC", data: fileData, options: FileOptions(cacheControl: "", contentType: "image/png", upsert: true, duplex: nil, metadata: ["x": AnyJSON.string("ABC")], headers: ["HeaderA": "ValueA"]))

            let _ = (removed, updated, downloaded, fileInfo, signedUploadURL, signedUploadResponse, buckets, bucket)
            #endif
        }

        let sopts = SearchOptions(limit: 10, offset: 0, sortBy: nil, search: fileName)
        let found: [FileObject] = try await images.list(path: folder, options: sopts)
        XCTAssertEqual(1, found.count)

        let publicURL1 = try images.getPublicURL(path: path, download: false, options: nil)
        logger.log("created publicURL1: \(publicURL1.absoluteString)") // e.g. https://zncizygaxuzzvxnsfdvp.supabase.co/storage/v1/object/public/images/public/tiny-B3038153-515C-4A15-835D-513CFD0D9D68.png

        let publicURL2 = try images.getPublicURL(path: path, download: false, options: TransformOptions(width: 200, height: 100, resize: "fill", quality: 100, format: nil))
        logger.log("created publicURL2: \(publicURL2.absoluteString)") // e.g. https://zncizygaxuzzvxnsfdvp.supabase.co/storage/v1/render/image/public/images/public/tiny-811DE754-0161-43BB-9DD1-1E120589D7D1.png?width=200&height=100&resize=fill&quality=100

        let signedURL: URL = try await images.createSignedURL(path: path, expiresIn: 60, download: false, transform: topts)
        logger.log("created signedURL: \(signedURL.absoluteString)") // e.g.: https://zncizygaxuzzvxnsfdvp.supabase.co/storage/v1/object/sign/images/public/tiny-402E081D-19EB-4D93-B9AC-7C25645EC511.png?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1cmwiOiJpbWFnZXMvcHVibGljL3RpbnktNDAyRTA4MUQtMTlFQi00RDkzLUI5QUMtN0MyNTY0NUVDNTExLnBuZyIsImlhdCI6MTczNjg5MDIzMCwiZXhwIjoxNzM2ODkwMjkwfQ.v5uYJSV2vMpfUMjnwu-aEIXlVFpwAZDEnQXhWYrpuaI

        let response2: [FileObject] = try await images.remove(paths: [path])
        XCTAssertEqual(1, response2.count)

        XCTAssertEqual(data.base64EncodedString(), fileData.base64EncodedString())
    }
}

// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
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
    override func setUp() {
        #if SKIP
        // enable calling minimalSettings() when setting up Auth for the purpoases of unit tests
        System.setProperty("skip_supabase_auth_minimalSettings", "1")
        #endif
    }

    func testSkipSupabaseAuth() async throws {
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


            try await ac.signOut()
            try await ac.signOut(scope: .global)
            try await ac.signOut(scope: .local)
            try await ac.signOut(scope: .others)

            //let _: AsyncStream<(event: AuthChangeEvent, session: Session?)> = ac.authStateChanges

            XCTFail("signIn should have failed")
        } catch {
            // expected
        }

        // check for unsupported API
        // SKIP NOWARN
        if false {
            #if !SKIP
            let signUpResponse1: AuthResponse = try await ac.signUp(email: "", password: "", data: [:], redirectTo: nil, captchaToken: "")
            let signUpResponse2: AuthResponse = try await ac.signUp(phone: "", password: "", channel: MessagingChannel.whatsapp, data: [:], captchaToken: "")

            let session1: Session = try await ac.exchangeCodeForSession(authCode: "")
            let session2: Session = try await ac.setSession(accessToken: "", refreshToken: "")
            let session3: Session = try await ac.refreshSession(refreshToken: "")

            try await ac.signInAnonymously(data: ["key": .string("value")])

            let ssoSession1 = try await ac.signInWithSSO(domain: "", redirectTo: nil, captchaToken: "")
            let ssoSession2 = try await ac.signInWithSSO(providerId: "", redirectTo: nil, captchaToken: "")
            try await ac.signInWithOTP(phone: "", channel: MessagingChannel.sms, shouldCreateUser: false, data: [:], captchaToken: "")
            try await ac.signInWithOTP(email: "", redirectTo: nil, shouldCreateUser: false, data: [:], captchaToken: "")

            try await ac.signInWithOAuth(provider: Provider.apple, redirectTo: nil, scopes: "", queryParams: [(name: "", value: "")]) { session in
            }
            #endif
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

            // File info and existence check (now available on both platforms)
            let fileInfo: FileObjectV2 = try await images.info(path: path)
            let exists = try await images.exists(path: path)
            XCTAssertTrue(exists, "file did not exist at: \(path)")

            // Signed upload URL API (now available on both platforms)
            let signedUploadURL: SignedUploadURL = try await images.createSignedUploadURL(path: path, options: CreateSignedUploadURLOptions(upsert: true))
            let signedUploadResponse: SignedURLUploadResponse = try await images.uploadToSignedURL(path, token: signedUploadURL.token, data: fileData, options: FileOptions(contentType: "image/png", upsert: true))

            // Multiple signed URLs (now available on both platforms)
            let signedURLs: [URL] = try await images.createSignedURLs(paths: [path], expiresIn: 60)

            let _ = removed; let _ = updated; let _ = downloaded
            let _ = fileInfo; let _ = signedUploadURL; let _ = signedUploadResponse
            let _ = signedURLs; let _ = buckets; let _ = bucket
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

    func testSupabaseStorageInfoAndExists() async throws {
        let bucketName = "images"
        let fileName = "info-test-\(UUID().uuidString).png"
        let path = "public/" + fileName
        let fileData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4z8AAAAMBAQD3A0FDAAAAAElFTkSuQmCC")!

        let images = client.storage.from(bucketName)

        // Upload a file
        let _: FileUploadResponse = try await images.upload(path, data: fileData, options: FileOptions(contentType: "image/png"))

        // Check exists
        let doesExist = try await images.exists(path: path)
        XCTAssertTrue(doesExist, "File should exist after upload")

        // Get file info
        let fileInfo: FileObjectV2 = try await images.info(path: path)
        XCTAssertTrue(fileInfo.name.contains(fileName), "Expected name to contain \(fileName), got \(fileInfo.name)")
        XCTAssertTrue(fileInfo.size ?? 0 > 0, "File size should be > 0")

        // Create multiple signed URLs
        let urls = try await images.createSignedURLs(paths: [path], expiresIn: 60, download: false)
        XCTAssertEqual(urls.count, 1)

        // Clean up
        let _ = try await images.remove(paths: [path])

        // Check no longer exists
        let existsAfterRemove = try await images.exists(path: path)
        XCTAssertFalse(existsAfterRemove, "File should not exist after removal")
    }

    func testSkipSupabaseAuthSession() async throws {
        let ac: AuthClient = client.auth

        // Verify currentSession is nil before sign-in
        XCTAssertNil(ac.currentSession)

        // On Skip, session getter should throw when not signed in
        #if SKIP
        do {
            let _ = try ac.session
            XCTFail("session should throw when not signed in")
        } catch {
            // expected: AuthError.sessionMissing
        }
        #endif
    }

    func testSkipSupabaseAuthTypes() throws {
        // Verify SignOutScope enum values
        let scopes: [SignOutScope] = [.global, .local, .others]
        XCTAssertEqual(scopes.count, 3)

        // Verify UserAttributes construction
        let attrs = UserAttributes(email: "test@example.com", password: "newpass")
        XCTAssertEqual(attrs.email, "test@example.com")
        XCTAssertEqual(attrs.password, "newpass")
        XCTAssertNil(attrs.phone)
    }

    func testSkipSupabaseDatabaseLike() async throws {
        // Ensure test data exists
        // SKIP NOWARN
        let _: PostgrestResponse<Void> = try await client.from("countries").delete().gte("id", value: 0).execute()

        // SKIP NOWARN
        let _: PostgrestResponse<Void> = try await client.from("countries")
            .insert(Country(id: 10, name: "Australia"))
            .execute()
        // SKIP NOWARN
        let _: PostgrestResponse<Void> = try await client.from("countries")
            .insert(Country(id: 11, name: "Austria"))
            .execute()
        // SKIP NOWARN
        let _: PostgrestResponse<Void> = try await client.from("countries")
            .insert(Country(id: 12, name: "Brazil"))
            .execute()

        // Test like filter (case-sensitive)
        let likeResp: PostgrestResponse<[Country]> = try await client
            .from("countries")
            .select()
            .like("name", pattern: "Aus%")
            .execute(options: FetchOptions(head: false, count: CountOption.exact))
        XCTAssertEqual(likeResp.value.count, 2) // Australia and Austria

        // Test ilike filter (case-insensitive)
        let ilikeResp: PostgrestResponse<[Country]> = try await client
            .from("countries")
            .select()
            .ilike("name", pattern: "aus%")
            .execute(options: FetchOptions(head: false, count: CountOption.exact))
        XCTAssertEqual(ilikeResp.value.count, 2) // Australia and Austria

        // Test is filter for null check
        let isNullResp: PostgrestResponse<[Country]> = try await client
            .from("countries")
            .select()
            .is("gdp", value: nil)
            .execute(options: FetchOptions(head: false, count: CountOption.exact))
        XCTAssertGreaterThanOrEqual(isNullResp.value.count, 3) // All 3 have nil gdp

        // Clean up
        // SKIP NOWARN
        let _: PostgrestResponse<Void> = try await client.from("countries").delete().gte("id", value: 0).execute()
    }

    func testSkipSupabaseOptions() throws {
        // Verify CountOption enum values
        let counts: [CountOption] = [.exact, .planned, .estimated]
        XCTAssertEqual(counts.count, 3)

        // Verify PostgrestReturningOptions enum values
        let returningOpts: [PostgrestReturningOptions] = [.minimal, .representation]
        XCTAssertEqual(returningOpts.count, 2)

        // Verify FetchOptions construction
        let opts = FetchOptions(head: true, count: .exact)
        XCTAssertTrue(opts.head)
        XCTAssertEqual(opts.count, .exact)

        // Verify TextSearchType enum values
        let searchTypes: [TextSearchType] = [.plain, .phrase, .websearch]
        XCTAssertEqual(searchTypes.count, 3)
    }

    func testSkipSupabaseStorageOptions() throws {
        // Verify BucketOptions construction
        let bopts = BucketOptions(public: true, fileSizeLimit: "10mb", allowedMimeTypes: ["image/*"])
        XCTAssertTrue(bopts.public)
        XCTAssertEqual(bopts.fileSizeLimit, "10mb")

        // Verify FileOptions construction
        let fopts = FileOptions(contentType: "image/png", upsert: true)
        XCTAssertEqual(fopts.contentType, "image/png")
        XCTAssertTrue(fopts.upsert)
        XCTAssertEqual(fopts.cacheControl, "3600")

        // Verify TransformOptions construction
        let topts = TransformOptions(width: 200, height: 100, resize: "cover", quality: 80)
        XCTAssertEqual(topts.width, 200)
        XCTAssertEqual(topts.height, 100)
        XCTAssertEqual(topts.resize, "cover")
        XCTAssertEqual(topts.quality, 80)

        // Verify SearchOptions construction
        let sopts = SearchOptions(limit: 50, offset: 10, search: "test")
        XCTAssertEqual(sopts.limit, 50)
        XCTAssertEqual(sopts.offset, 10)
        XCTAssertEqual(sopts.search, "test")

        // Verify DestinationOptions
        let dopts = DestinationOptions(destinationBucket: "other")
        XCTAssertEqual(dopts.destinationBucket, "other")
    }
}

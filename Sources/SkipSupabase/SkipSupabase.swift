// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
#if !SKIP
@_exported import Supabase
#else
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.gotrue.FlowType
import io.github.jan.supabase.createSupabaseClient

//import io.github.jan.supabase.auth.Auth
//import io.github.jan.supabase.auth.auth
//import io.github.jan.supabase.gotrue.GoTrue
//import io.github.jan.supabase.gotrue.gotrue
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.storage.Storage
import io.github.jan.supabase.storage.storage

import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns

#endif

#if SKIP

//public typealias SupabaseClient = io.github.jan.supabase.SupabaseClient
//
//public func SupabaseClient(supabaseURL: URL, supabaseKey: String) -> SupabaseClient {
//    return createSupabaseClient(supabaseUrl: supabaseURL.absoluteString, supabaseKey: supabaseKey) {
//        install(Postgrest)
//    }
//}

public class SupabaseClient {
    private let client: io.github.jan.supabase.SupabaseClient

    public init(supabaseURL: URL, supabaseKey: String) {
        self.client = createSupabaseClient(supabaseUrl: supabaseURL.absoluteString, supabaseKey: supabaseKey) {
            // defaultSerializer = JacksonSerializer() // TODO: custom serializer that uses Skip Encodable/Decodable

            //install(Auth)
            install(Postgrest)
            install(Storage) {
                //transferTimeout = 120.seconds // Default: 120 seconds
            }
        }
    }

    public func from(_ tableName: String) -> PostgrestQueryBuilder {
        PostgrestQueryBuilder(builder: client.from(tableName))
    }
}

public class PostgrestQueryBuilder {
    private let builder: io.github.jan.supabase.postgrest.query.PostgrestQueryBuilder

    internal init(builder: io.github.jan.supabase.postgrest.query.PostgrestQueryBuilder) {
        self.builder = builder
    }
}

#endif

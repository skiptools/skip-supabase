// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation

#if !SKIP
@_exported import Supabase
#else
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.FlowType
import io.github.jan.supabase.createSupabaseClient

import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.minimalSettings
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.storage.Storage
import io.github.jan.supabase.storage.storage

import io.github.jan.supabase.postgrest.RpcMethod
import io.github.jan.supabase.postgrest.rpc

import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order

import io.github.jan.supabase.SupabaseSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import kotlin.time.Duration.Companion.seconds
import kotlin.reflect.KType
import kotlin.reflect.javaType

#endif

#if !SKIP
extension PostgrestResponse {
    //var value: T

//    func getValue<T>(ofType: T.Type) throws -> T {
//        return self.value
//    }
}
#endif

#if SKIP

public class SupabaseClient {
    fileprivate let client: io.github.jan.supabase.SupabaseClient

    public init(supabaseURL: URL, supabaseKey: String) {
        self.client = createSupabaseClient(supabaseUrl: supabaseURL.absoluteString, supabaseKey: supabaseKey) {
            defaultSerializer = CodableSerializer()

            install(Auth) {
                // enable only when running in Robolectric tests
                if System.getProperty("skip_supabase_auth_minimalSettings") != nil {
                    minimalSettings() // “Applies minimal settings to the [AuthConfig]. This is useful for server side applications, where you don't need to store the session or code verifier.”
                }

                // needed or else NPE on startup: https://github.com/supabase-community/supabase-kt/issues/69
                // and java.lang.ExceptionInInitializerError: Exception java.lang.IllegalStateException: Failed to create default settings for SettingsSessionManager. You might have to provide a custom settings instance or a custom session manager. Learn more at https://github.com/supabase-community/supabase-kt/wiki/Session-Saving
                //sessionManager = io.github.jan.supabase.auth.SettingsSessionManager(com.russhwolf.settings.MapSettings())
                //sessionManager = io.github.jan.supabase.auth.MemorySessionManager()
            }
            install(Postgrest)
            install(Storage) {
                transferTimeout = 120.seconds // Default: 120 seconds
                resumable {
                    cache = io.github.jan.supabase.storage.resumable.MemoryResumableCache()
                }
            }
        }
    }
}

public typealias JSONObject = [String: AnyJSON]
public typealias JSONArray = [AnyJSON]

/// An enumeration that represents JSON-compatible values of various types.
/// Copied from Supabase.Helpers.AnyJSON
public enum AnyJSON: Hashable {
    /// Represents a `null` JSON value.
    case null
    /// Represents a JSON boolean value.
    case bool(Bool)
    /// Represents a JSON number (integer) value.
    case integer(Int)
    /// Represents a JSON number (floating-point) value.
    case double(Double)
    /// Represents a JSON string value.
    case string(String)
    /// Represents a JSON object (dictionary) value.
    case object(JSONObject)
    /// Represents a JSON array (list) value.
    case array(JSONArray)
}

func dict2JsonObject(_ dict: [String: AnyJSON]?) -> kotlinx.serialization.json.JsonObject? {
    // TODO: convert Swift [String: AnyJSON]? parameter to Kotlin JsonObject?
    return nil
}

func instant2date(_ instant: kotlinx.datetime.Instant?) -> Date? {
    guard let instant = instant else { return nil }
    return Date(platformValue: java.util.Date(instant.toEpochMilliseconds()))
}

/// Create a DateFormatter to use for encoding and decoding dates from Supabase
///
/// - Note: must be public in order to be usable from `@inline(__always) public func execute`
func createSupabaseDateFormatter(forDecoding: Bool, fractional: Bool = false) -> DateFormatter {
    let fmt = ISO8601DateFormatter()
    if fractional {
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    } else {
        fmt.formatOptions = [.withInternetDateTime]
    }
    return fmt
}

class CodableSerializer: io.github.jan.supabase.SupabaseSerializer {
    override func encode<T: Any>(type: kotlin.reflect.KType, value: T) -> String {
        var v: Any = value
        // individual values are wrapped in a Collections$SingletonList instance, so they need to be converted to a skip.lib.Array to encode them
        if let collection = v as? java.util.Collection<Any> {
            v = skip.lib.Array(collection)
        }

        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .formatted(createSupabaseDateFormatter(forDecoding: false))

        let data = try encoder.encode(v)
        return String(data: data, encoding: String.Encoding.utf8)!
    }

    // SKIP INSERT: @OptIn(ExperimentalStdlibApi::class)
    override func decode<T: Any>(type: kotlin.reflect.KType, value: String) -> T {
        fatalError("deserialize requires reified type; decode at call site instead")

//        // cannot use Kotlin serialization (which may not be compatible with our Codable serialization)
//        // Caused by: java.lang.IllegalArgumentException: Captured type parameter T from generic non-reified function. Such functionality cannot be supported because T is erased, either specify serializer explicitly or make calling function inline with reified T.
//        //return Json.decodeFromString(serializer(type), value) as T
//
//        let data = value.data(using: String.Encoding.utf8) ?? Data()
//
//        let decoder = JSONDecoder()
//        //return try decoder.decode(T.self, data) // Argument type mismatch: actual type is 'kotlin.reflect.KClass<ERROR CLASS: Type parameter T in qualified access>', but 'kotlin.reflect.KClass<T>' was expected.
//
//        //return try decoder.decode(type, data) // Argument type mismatch: actual type is 'kotlin.reflect.KType', but 'kotlin.reflect.KClass<T>' was expected.
//
////        // let klass: kotlin.reflect.KClass<T> = type.classifier as kotlin.reflect.KClass<T> // Argument type mismatch: actual type is 'kotlin.reflect.KClass<T>', but 'kotlin.reflect.KClass<T>' was expected.
//
//        let klassifier: kotlin.reflect.KClassifier = type.classifier!
//
////        if let param = klassifier as? kotlin.reflect.KTypeParameter {
////            print("### klassifier param: \(param) \(param.upperBounds)")
////        }
////
//        // SKIP INSERT: val klass: kotlin.reflect.KClass<T> = klassifier as kotlin.reflect.KClass<T>
    }
}

#endif

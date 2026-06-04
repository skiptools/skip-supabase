// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
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
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.doubleOrNull
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

/// Convert a Swift `[String: AnyJSON]?` to a Kotlin `JsonObject?`.
/// Returns `nil` when the input is `nil`.
func dict2JsonObject(_ dict: [String: AnyJSON]?) -> kotlinx.serialization.json.JsonObject? {
    guard let dict = dict else { return nil }
    let map = kotlin.collections.mutableMapOf<String, kotlinx.serialization.json.JsonElement>()
    for key in dict.keys {
        if let value = dict[key] {
            map.put(key, anyJSON2JsonElement(value))
        }
    }
    return kotlinx.serialization.json.JsonObject(map)
}

/// Recursively convert an `AnyJSON` value to a Kotlin `JsonElement`.
func anyJSON2JsonElement(_ value: AnyJSON) -> kotlinx.serialization.json.JsonElement {
    switch value {
    case .null:
        return kotlinx.serialization.json.JsonNull
    case .bool(let b):
        return kotlinx.serialization.json.JsonPrimitive(b)
    case .integer(let i):
        return kotlinx.serialization.json.JsonPrimitive(i)
    case .double(let d):
        return kotlinx.serialization.json.JsonPrimitive(d)
    case .string(let s):
        return kotlinx.serialization.json.JsonPrimitive(s)
    case .object(let obj):
        return dict2JsonObject(obj)!
    case .array(let arr):
        let list = kotlin.collections.mutableListOf<kotlinx.serialization.json.JsonElement>()
        for v in arr {
            list.add(anyJSON2JsonElement(v))
        }
        return kotlinx.serialization.json.JsonArray(list)
    }
}

/// Convert a Kotlin `JsonObject?` to a Swift `[String: AnyJSON]?`.
/// Returns `nil` when the input is `nil`.
func jsonObject2Dict(_ obj: kotlinx.serialization.json.JsonObject?) -> [String: AnyJSON]? {
    guard let obj = obj else { return nil }
    var result: [String: AnyJSON] = [:]
    for entry in obj {
        result[entry.key] = jsonElement2AnyJSON(entry.value)
    }
    return result
}

/// Recursively convert a Kotlin `JsonElement` to an `AnyJSON` value.
func jsonElement2AnyJSON(_ value: kotlinx.serialization.json.JsonElement) -> AnyJSON {
    if value is kotlinx.serialization.json.JsonNull {
        return .null
    }
    if let obj = value as? kotlinx.serialization.json.JsonObject {
        var result: [String: AnyJSON] = [:]
        for entry in obj {
            result[entry.key] = jsonElement2AnyJSON(entry.value)
        }
        return .object(result)
    }
    if let array = value as? kotlinx.serialization.json.JsonArray {
        return .array(Array(array).map { jsonElement2AnyJSON($0) })
    }
    if let primitive = value as? kotlinx.serialization.json.JsonPrimitive {
        if primitive.isString {
            return .string(primitive.content)
        }
        if let b = primitive.booleanOrNull {
            return .bool(b)
        }
        if let l = primitive.longOrNull {
            return .integer(Int(l))
        }
        if let d = primitive.doubleOrNull {
            return .double(d)
        }
        return .string(primitive.content)
    }
    return .null
}

// SKIP INSERT: @OptIn(kotlin.time.ExperimentalTime::class)
func instant2date(_ instant: kotlin.time.Instant?) -> Date? {
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
    override func encode<T>(type: kotlin.reflect.KType, value: T) -> String {
        // SKIP REPLACE: var v: Any = value as Any
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
    override func decode<T>(type: kotlin.reflect.KType, value: String) -> T {
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

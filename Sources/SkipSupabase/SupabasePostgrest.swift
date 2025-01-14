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
import kotlin.reflect.KType
import kotlin.reflect.javaType

#endif

#if SKIP

// SKIP NOWARN
// This extension will be moved into its extended type definition when translated to Kotlin. It will not be able to access this file's private types or fileprivate members
extension SupabaseClient {
    public func from(_ tableName: String) -> PostgrestQueryBuilder {
        PostgrestQueryBuilder(builder: client.from(tableName))
    }

    @inline(__always) public func rpc(_ fn: String) async -> PostgrestFilterBuilder {
        return PostgrestRpcBuilder(fname: fn, client: client, params: nil).createFilterBuilder()
    }

    public func rpc(_ fn: String, params: Dictionary<String, String>) async -> PostgrestFilterBuilder {
        return PostgrestRpcBuilder(fname: fn, client: client, params: params).createFilterBuilder()
    }
}

public protocol PostgrestExecutor {
    func execute(requestBuilder: (io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> ()) async -> io.github.jan.supabase.postgrest.result.PostgrestResult
}

public final class PostgrestRpcBuilder: PostgrestExecutor {
    private let fname: String
    private let client: io.github.jan.supabase.SupabaseClient
    private let params: Dictionary<String, String>?

    init(fname: String, client: io.github.jan.supabase.SupabaseClient, params: Dictionary<String, String>? = nil) {
        self.fname = fname
        self.client = client
        self.params = params
    }

    func createFilterBuilder() -> PostgrestFilterBuilder {
        return PostgrestFilterBuilder(executor: self)
    }

    public override func execute(requestBuilder: (io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> ()) async -> io.github.jan.supabase.postgrest.result.PostgrestResult {
        guard let params = self.params else {
            // SKIP NOWARN
            return await self.client.postgrest.rpc(fname)
        }
        
        let jsonMap = kotlin.collections.mutableMapOf<String, kotlinx.serialization.json.JsonElement>()
        
        for key in params.keys {
            let jsonElement = kotlinx.serialization.json.Json.parseToJsonElement("\(params[key])")
            jsonMap.put(key, jsonElement)
        }
        
        let rpcParams = kotlinx.serialization.json.JsonObject(jsonMap)
        // SKIP NOWARN
        return await self.client.postgrest.rpc(fname, rpcParams)
    }
    
}

public final class PostgrestQueryBuilder : PostgrestExecutor {
    fileprivate let builder: io.github.jan.supabase.postgrest.query.PostgrestQueryBuilder
    fileprivate var operation: Operation = .select
    fileprivate var returning: PostgrestReturningOptions = .minimal

    internal init(builder: io.github.jan.supabase.postgrest.query.PostgrestQueryBuilder) {
        self.builder = builder
    }

    private func createFilterBuilder(operation: Operation) -> PostgrestFilterBuilder {
        synchronized(self) {
            self.operation = operation
        }
        return PostgrestFilterBuilder(executor: self)
    }

    public func delete() -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .delete)
    }

    public func select(_ columns: String = "*", head: Bool = false, count: CountOption? = nil) -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .select)
            .countOption(count)
    }

    public func update(value: Any) -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .update(value))
    }

    public func insert(value: Any, returning: PostgrestReturningOptions = .minimal) -> PostgrestFilterBuilder {
        self.returning = returning
        return createFilterBuilder(operation: .insert(value))
    }

    public func upsert(value: Any) -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .upsert(value))
    }

    public enum Operation {
        case select, delete, insert(Any), update(Any), upsert(Any)
    }

    public override func execute(requestBuilder: (io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> ()) async -> io.github.jan.supabase.postgrest.result.PostgrestResult {
        let rb: (io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> () = { x in
            // x.returning = self.returning.kt // Cannot access 'returning': it is private in 'io/github/jan/supabase/postgrest/query/PostgrestRequestBuilder'.

            // since we can't manually set the returning value, go through a function that does it as a side-effect
            if self.returning == .representation {
                x.select(columns: Columns.ALL)
            }
            requestBuilder(x)
        }

        switch self.operation {
        case .select:
            return builder.select(request: rb)
        case .delete:
            return builder.delete(request: rb)
        case .insert(let x):
            return builder.insert(value: x, request: rb)
        case .update(let x):
            return builder.update(value: x, request: rb)
        case .upsert(let x):
            return builder.upsert(value: x, request: rb)
        }
    }

}

private func _createSupabaseJSONDecoder() -> JSONDecoder {
    let decoder = try JSONDecoder()
    decoder.dataDecodingStrategy = .base64
    // Supabase transmits dates with either fractional or non-fractional seconds
    // https://github.com/supabase/supabase-swift/blob/main/Sources/Helpers/AnyJSON/AnyJSON%2BCodable.swift

    let fmt1 = createSupabaseDateFormatter(forDecoding: true, fractional: true)
    let fmt2 = createSupabaseDateFormatter(forDecoding: true, fractional: false)

    let decodeDate = { (decoder: Decoder) throws -> Date in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)

        let date = fmt1.date(from: dateString) ?? fmt2.date(from: dateString)

        guard let decodedDate = date else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Invalid date format: \(dateString)"))
        }

        return decodedDate
    }

    decoder.dateDecodingStrategy = .custom(decodeDate)
    return decoder
}

public let _supabaseJSONDecoder = _createSupabaseJSONDecoder()


public class PostgrestBuilder {
    // SKIP INSERT: @PublishedApi
    fileprivate let executor: PostgrestExecutor

    init(executor: PostgrestExecutor) {
        self.executor = executor
    }

    // TODO: also handle single Decodable argument, but we cannot disambiguate between them based solely on return type
//    @inline(__always) public func execute<T: Decodable>(options: FetchOptions? = nil) async -> PostgrestResponse<T> {
//        // TODO: handle options
//        let result: io.github.jan.supabase.postgrest.result.PostgrestResult = self.executor.execute(requestBuilder: buildRequest())
//        let data = result.data.data(using: String.Encoding.utf8)! // the SupabaseKt data is actually a String
//        let value = try JSONDecoder().decode(T.self, from: data)
//        return PostgrestResponse<T>(result: result, data: data, value: value)
//    }

    @inline(__always) public func execute<T: Decodable>(options: FetchOptions? = nil) async -> PostgrestResponse<[T]> {
        // TODO: handle options
        let result: io.github.jan.supabase.postgrest.result.PostgrestResult = self.executor.execute(requestBuilder: buildRequest())
        let data = result.data.data(using: String.Encoding.utf8)! // the SupabaseKt data is actually a String
        let value = _supabaseJSONDecoder.decode([T].self, from: data)
        return PostgrestResponse<[T]>(result: result, data: data, value: value)
    }

    @inline(__always) public func execute(_ v1: Void? = nil) async -> PostgrestResponse<Void> {
        // TODO: handle options
        let result: io.github.jan.supabase.postgrest.result.PostgrestResult = self.executor.execute(requestBuilder: buildRequest())
        let data = result.data.data(using: String.Encoding.utf8)! // the SupabaseKt data is actually a String
        return PostgrestResponse<Void>(result: result, data: data, value: Void)
    }

    // SKIP INSERT: @PublishedApi
    func buildRequest() -> (io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> () {
        { _ in
        }
    }
}

public class PostgrestTransformBuilder : PostgrestBuilder {
    fileprivate var transforms: [(io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> ()] = []

    /// Order the query result by `column`.
    ///
    /// You can call this method multiple times to order by multiple columns.
    /// You can order referenced tables, but it only affects the ordering of theparent table if you use `!inner` in the query.
    ///
    /// - Parameters:
    ///   - column: The column to order by.
    ///   - ascending: If `true`, the result will be in ascending order.
    ///   - nullsFirst: If `true`, `null`s appear first. If `false`, `null`s appear last.
    ///   - referencedTable: Set this to order a referenced table by its columns.
    public func order(_ column: String, ascending: Bool = true, nullsFirst: Bool = false, referencedTable: String? = nil) -> PostgrestTransformBuilder {
        synchronized(self) {
            transforms.append { builder in
                builder.order(column: column, order: ascending ? Order.ASCENDING : Order.DESCENDING, nullsFirst: nullsFirst, referencedTable: referencedTable)
            }
        }
        return self
    }

    /// Limits the query result by `count`.
    /// - Parameters:
    ///   - count: The maximum number of rows to return.
    ///   - referencedTable: Set this to limit rows of referenced tables instead of the parent table.
    public func limit(_ count: Int, referencedTable: String? = nil) -> PostgrestTransformBuilder {
        synchronized(self) {
            transforms.append { builder in
                builder.limit(count: Long(count), referencedTable: referencedTable)
            }
        }
        return self
    }

    /// Limit the query result by starting at an offset (`from`) and ending at the offset (`from + to`).
    ///
    /// Only records within this range are returned.
    /// This respects the query order and if there is no order clause the range could behave unexpectedly.
    /// The `from` and `to` values are 0-based and inclusive: `range(from: 1, to: 3)` will include the second, third and fourth rows of the query.
    ///
    /// - Parameters:
    ///   - from: The starting index from which to limit the result.
    ///   - to: The last index to which to limit the result.
    ///   - referencedTable: Set this to limit rows of referenced tables instead of the parent table.
    public func range(from: Int, to: Int, referencedTable: String? = nil) -> PostgrestTransformBuilder {
        synchronized(self) {
            transforms.append { builder in
                builder.range(from: Long(from), to: Long(to), referencedTable: referencedTable)
            }
        }
        return self
    }

    /// Return `value` as a single object instead of an array of objects.
    ///
    /// Query result must be one row (e.g. using `.limit(1)`), otherwise this returns an error.
    public func single() -> PostgrestTransformBuilder {
        return self
    }

    ///  Return `value` as a string in CSV format.
    @available(*, unavailable)
    public func csv() -> PostgrestTransformBuilder {
        self
    }

    /// Return `value` as an object in [GeoJSON](https://geojson.org) format.
    @available(*, unavailable)
    public func geojson() -> PostgrestTransformBuilder {
        self
    }

    /// Return `data` as the EXPLAIN plan for the query.
    ///
    /// You need to enable the [db_plan_enabled](https://supabase.com/docs/guides/database/debugging-performance#enabling-explain)
    /// setting before using this method.
    ///
    /// - Parameters:
    ///   - analyze: If `true`, the query will be executed and the actual run time will be returned
    ///   - verbose: If `true`, the query identifier will be returned and `data` will include the
    /// output columns of the query
    ///   - settings: If `true`, include information on configuration parameters that affect query
    /// planning
    ///   - buffers: If `true`, include information on buffer usage
    ///   - wal: If `true`, include information on WAL record generation
    ///   - format: The format of the output, can be `"text"` (default) or `"json"`
    @available(*, unavailable)
    public func explain(analyze: Bool = false, verbose: Bool = false, settings: Bool = false, buffers: Bool = false, wal: Bool = false, format: String = "text") -> PostgrestTransformBuilder {
        self
    }
}

public class PostgrestFilterBuilder : PostgrestTransformBuilder {
    fileprivate var filters: [(io.github.jan.supabase.postgrest.query.filter.PostgrestFilterBuilder) -> ()] = []
    fileprivate var countOption: CountOption? = nil

    fileprivate func countOption(_ countOption: CountOption?) -> PostgrestFilterBuilder {
        synchronized(self) { self.countOption = countOption }
        return self
    }

    public func eq(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.eq(column: columnName, value: value) })
    }

    public func neq(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.neq(column: columnName, value: value) })
    }

    public func gt(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.gt(columnName, value: value) })
    }

    public func gte(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.gte(column: columnName, value: value) })
    }

    public func lt(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.lt(column: columnName, value: value) })
    }

    public func lte(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.lte(column: columnName, value: value) })
    }

    public func containedBy(_ columnName: String, _ value: [Any]) -> PostgrestFilterBuilder {
        filter({ $0.contained(column: columnName, values: value.toList()) })
    }

    public func `in`(_ columnName: String, _ values: [Any]) -> PostgrestFilterBuilder {
        filter({ $0.isIn(column: columnName, values: values.toList()) })
    }

    public func contains(_ columnName: String, _ value: [Any]) -> PostgrestFilterBuilder {
        filter({ $0.contains(column: columnName, values: value.toList()) })
    }

    public func equals(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.eq(column: columnName, value: value) })
    }

    @available(*, unavailable)
    public func fts(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        //filter({ $0.fts(column: columnName, value: value) })
        self
    }

    public func greaterThan(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.gt(column: columnName, value: value) })
    }

    public func greaterThanOrEquals(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.gte(column: columnName, value: value) })
    }

    public func lowerThan(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.lt(column: columnName, value: value) })
    }

    public func lowerThanOrEquals(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.lte(column: columnName, value: value) })
    }

    /// Adds the given filter operation to the list of filters that will be applied when the request is built
    private func filter(_ operation: (io.github.jan.supabase.postgrest.query.filter.PostgrestFilterBuilder) -> ()) -> PostgrestFilterBuilder {
        synchronized(self) { filters.append(operation) }
        return self
    }

    override func buildRequest() -> (io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> () {
        return { builder in
            if !filters.isEmpty {
                builder.filter {
                    for filter in filters {
                        filter(self)
                    }
                }
            }

            // order, limit, range, etc.
            if !transforms.isEmpty {
                for transform in transforms {
                    transform(builder)
                }
            }

            if let countOption = countOption {
                switch countOption {
                case .exact: builder.count(io.github.jan.supabase.postgrest.query.Count.EXACT)
                case .estimated: builder.count(io.github.jan.supabase.postgrest.query.Count.ESTIMATED)
                case .planned: builder.count(io.github.jan.supabase.postgrest.query.Count.PLANNED)
                }
            }
        }
    }
}

public struct PostgrestResponse<T> {
    private let result: io.github.jan.supabase.postgrest.result.PostgrestResult
    public let data: Data
    public let value: T

    // SKIP INSERT: @PublishedApi
    init(result: io.github.jan.supabase.postgrest.result.PostgrestResult, data: Data, value: T) {
        self.result = result
        self.data = data
        self.value = value
    }

    public var count: Int? {
        return result.countOrNull()?.toInt()
    }

    public var status: Int {
        let headers: io.ktor.http.Headers = result.headers
        // default headers does not seem to contain a "status" key, so fall back to 200 (success)
        // [alt-svc, cf-cache-status, cf-ray, content-profile, content-range, content-type, date, sb-gateway-version, sb-project-ref, server, strict-transport-security, vary, x-content-type-options, x-envoy-attempt-count, x-envoy-upstream-service-time]
        return headers["status"]?.split(" ")?.drop(1).firstOrNull()?.toIntOrNull() ?? 200
    }
}


/// Options for querying Supabase.
public struct FetchOptions: Sendable {
    /// Set head to true if you only want the count value and not the underlying data.
    public let head: Bool

    /// count options can be used to retrieve the total number of rows that satisfies the
    /// query. The value for count respects any filters (e.g. eq, gt), but ignores
    /// modifiers (e.g. limit, range).
    public let count: CountOption?

    public init(head: Bool = false, count: CountOption? = nil) {
        self.head = head
        self.count = count
    }
}

/// Returns count as part of the response when specified.
public enum CountOption: String, Sendable {
    /// Exact but slow count algorithm. Performs a `COUNT(*)` under the hood.
    case exact
    /// Approximated but fast count algorithm. Uses the Postgres statistics under the hood.
    case planned
    /// Uses exact count for low numbers and planned count for high numbers.
    case estimated
}

/// Enum of options representing the ways PostgREST can return values from the server.
///
/// https://postgrest.org/en/v9.0/api.html?highlight=PREFER#insertions-updates
public enum PostgrestReturningOptions: String, Sendable {
    /// Returns nothing from the server
    case minimal
    /// Returns a copy of the updated data.
    case representation

    var kt: io.github.jan.supabase.postgrest.query.Returning {
        switch self {
        case .minimal: return .Minimal
        case .representation: return .Representation()
        }
    }
}

/// The type of tsquery conversion to use on query.
public enum TextSearchType: String, Sendable {
    /// Uses PostgreSQL's plainto_tsquery function.
    case plain = "pl"
    /// Uses PostgreSQL's phraseto_tsquery function.
    case phrase = "ph"
    /// Uses PostgreSQL's websearch_to_tsquery function.
    /// This function will never raise syntax errors, which makes it possible to use raw user-supplied
    /// input for search, and can be used with advanced operators.
    case websearch = "w"
}

#endif

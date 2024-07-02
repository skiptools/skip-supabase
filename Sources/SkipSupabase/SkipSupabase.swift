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

public class SupabaseClient {
    fileprivate let client: io.github.jan.supabase.SupabaseClient

    public init(supabaseURL: URL, supabaseKey: String) {
        self.client = createSupabaseClient(supabaseUrl: supabaseURL.absoluteString, supabaseKey: supabaseKey) {
            defaultSerializer = CodableSerializer()

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

class CodableSerializer: io.github.jan.supabase.SupabaseSerializer {

    override func encode<T: Any>(type: kotlin.reflect.KType, value: T) -> String {
        var v: Any = value
        if let collection = v as? java.util.Collection<Any> {
            v = skip.lib.Array(collection)
        }

        let encoder = JSONEncoder()
        let data = try encoder.encode(v)
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }

    override func decode<T: Any>(type: kotlin.reflect.KType, value: String) -> T {
        fatalError("TODO")
    }
}

public class PostgrestQueryBuilder {
    fileprivate let builder: io.github.jan.supabase.postgrest.query.PostgrestQueryBuilder
    fileprivate var operation: Operation = .select

    internal init(builder: io.github.jan.supabase.postgrest.query.PostgrestQueryBuilder) {
        self.builder = builder
    }

    private func createFilterBuilder(operation: Operation) -> PostgrestFilterBuilder {
        synchronized(self) {
            self.operation = operation
        }
        return PostgrestFilterBuilder(queryBuilder: self)
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
        createFilterBuilder(operation: .insert(value))
    }

    public func upsert(value: Any) -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .upsert(value))
    }

    public enum Operation {
        case select, delete, insert(Any), update(Any), upsert(Any)
    }

}

public class PostgrestBuilder {
    fileprivate let queryBuilder: PostgrestQueryBuilder

    init(queryBuilder: PostgrestQueryBuilder) {
        self.queryBuilder = queryBuilder
    }

//    public func execute(void: Void? = nil) async -> PostgrestResponse<Void> {
//        execute()
//    }

    public func execute<T>() async -> PostgrestResponse<T> {
        switch queryBuilder.operation {
        case .select:
            return PostgrestResponse(result: queryBuilder.builder.select(request: buildRequest()))
        case .delete:
            return PostgrestResponse(result: queryBuilder.builder.delete(request: buildRequest()))
        case .insert(let x):
            return PostgrestResponse(result: queryBuilder.builder.insert(value: x, request: buildRequest()))
        case .update(let x):
            return PostgrestResponse(result: queryBuilder.builder.update(value: x, request: buildRequest()))
        case .upsert(let x):
            return PostgrestResponse(result: queryBuilder.builder.upsert(value: x, request: buildRequest()))
        }

    }

    func buildRequest() -> (io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> () {
        { _ in
        }
    }
}

public class PostgrestTransformBuilder : PostgrestBuilder {
    /// Perform a SELECT on the query result.
    ///
    /// By default, `.insert()`, `.update()`, `.upsert()`, and `.delete()` do not return modified rows. By calling this method, modified rows are returned in `value`.
    ///
    /// - Parameters:
    ///   - columns: The columns to retrieve, separated by commas.
//    public func select(_ columns: String = "*") -> PostgrestTransformBuilder

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
//    public func order(
//      _ column: String,
//      ascending: Bool = true,
//      nullsFirst: Bool = false,
//      referencedTable: String? = nil
//    ) -> PostgrestTransformBuilder

    /// Limits the query result by `count`.
    /// - Parameters:
    ///   - count: The maximum number of rows to return.
    ///   - referencedTable: Set this to limit rows of referenced tables instead of the parent table.
//    public func limit(_ count: Int, referencedTable: String? = nil) -> PostgrestTransformBuilder

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
//    public func range(
//      from: Int,
//      to: Int,
//      referencedTable: String? = nil
//    ) -> PostgrestTransformBuilder

    /// Return `value` as a single object instead of an array of objects.
    ///
    /// Query result must be one row (e.g. using `.limit(1)`), otherwise this returns an error.
    public func single() -> PostgrestTransformBuilder {
        return self
    }

    ///  Return `value` as a string in CSV format.
//    public func csv() -> PostgrestTransformBuilder

    /// Return `value` as an object in [GeoJSON](https://geojson.org) format.
//    public func geojson() -> PostgrestTransformBuilder

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
//    public func explain(
//      analyze: Bool = false,
//      verbose: Bool = false,
//      settings: Bool = false,
//      buffers: Bool = false,
//      wal: Bool = false,
//      format: String = "text"
//    ) -> PostgrestTransformBuilder

}

public class PostgrestFilterBuilder : PostgrestTransformBuilder {
    //private var requests: [(io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> ()] = []
    fileprivate var filters: [(io.github.jan.supabase.postgrest.query.filter.PostgrestFilterBuilder) -> ()] = []
    fileprivate var countOption: CountOption? = nil

    fileprivate func countOption(_ countOption: CountOption?) -> PostgrestFilterBuilder {
        synchronized(self) { self.countOption = countOption }
        return self
    }

    public func eq(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.eq(columnName, value) })
    }

    public func neq(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.neq(columnName, value) })
    }

    public func gt(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.gt(columnName, value) })
    }

    public func gte(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.gte(columnName, value) })
    }

    public func lt(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.lt(columnName, value) })
    }

    public func lte(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.lte(columnName, value) })
    }

//    public func containedBy(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
//        filter({ $0.containedBy(columnName, value) })
//    }

//    public func `in`(_ columnName: String, _ value: [Any]) -> PostgrestFilterBuilder {
//        filter({ $0.in(columnName, value) })
//    }

    public func contains(_ columnName: String, _ value: [Any]) -> PostgrestFilterBuilder {
        filter({ $0.contains(columnName, value.toList()) })
    }

    public func equals(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.eq(columnName, value) })
    }

//    public func fts(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
//        filter({ $0.fts(columnName, value) })
//    }

    public func greaterThan(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.gt(columnName, value) })
    }

    public func greaterThanOrEquals(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.gte(columnName, value) })
    }

    public func lowerThan(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.lt(columnName, value) })
    }

    public func lowerThanOrEquals(_ columnName: String, _ value: Any) -> PostgrestFilterBuilder {
        filter({ $0.lte(columnName, value) })
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

    init(result: io.github.jan.supabase.postgrest.result.PostgrestResult) {
        self.result = result
    }

    public var count: Int? {
        result.countOrNull()?.toInt()
    }

    public var value: T! {
        nil // TODO
    }


    //public let data: Data
    //public let response: HTTPURLResponse
    //public let count: Int?
    //public let value: T

//    public var status: Int {
//        response.statusCode
//    }
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

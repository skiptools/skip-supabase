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

    func delete() -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .delete)
    }

    func select(_ columns: String = "*", head: Bool = false, count: CountOption? = nil) -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .select)
            .countOption(count)
    }

    func update(value: Any) -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .update(value))
    }

    func insert(value: Any) -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .insert(value))
    }

    func upsert(value: Any) -> PostgrestFilterBuilder {
        createFilterBuilder(operation: .upsert(value))
    }

    public enum Operation {
        case select, delete, insert(Any), update(Any), upsert(Any)
    }

}

public class PostgrestFilterBuilder {
    fileprivate let queryBuilder: PostgrestQueryBuilder
    //private var requests: [(io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> ()] = []
    fileprivate var filters: [(io.github.jan.supabase.postgrest.query.filter.PostgrestFilterBuilder) -> ()] = []
    fileprivate var countOption: CountOption? = nil

    init(queryBuilder: PostgrestQueryBuilder) {
        self.queryBuilder = queryBuilder
    }

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

    private func buildRequest() -> (io.github.jan.supabase.postgrest.query.PostgrestRequestBuilder) -> () {
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

    public func execute() async -> PostgrestResponse<Void> {
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
}

public struct PostgrestResponse<T> {
    private let result: io.github.jan.supabase.postgrest.result.PostgrestResult

    init(result: io.github.jan.supabase.postgrest.result.PostgrestResult) {
        self.result = result
    }

    public var count: Int64? {
        result.countOrNull()
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

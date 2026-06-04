// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation

#if !SKIP
@_exported import Supabase
#else
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.realtime.realtime
import io.github.jan.supabase.realtime.RealtimeChannel
import io.github.jan.supabase.realtime.channel
// NOTE: deliberately not importing io.github.jan.supabase.realtime.PostgresAction
// (or `Column`) — we declare our own protocol/struct with the same names below,
// and the supabase-kt types are referenced by fully qualified name in the
// conversion helpers.
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.Flow
#endif

#if SKIP

// SKIP NOWARN
extension SupabaseClient {
    /// The Realtime client for this Supabase project.
    public var realtimeV2: RealtimeClientV2 {
        RealtimeClientV2(realtime: client.realtime)
    }

    /// Creates (or returns the existing) realtime channel for the given topic.
    /// You must call ``RealtimeChannelV2/subscribe()`` on the returned channel before any events are delivered.
    public func channel(_ topic: String) -> RealtimeChannelV2 {
        return realtimeV2.channel(topic)
    }

    /// Removes a channel from the realtime client and unsubscribes it.
    public func removeChannel(_ channel: RealtimeChannelV2) async {
        await realtimeV2.removeChannel(channel)
    }

    /// Removes all currently registered channels.
    public func removeAllChannels() async {
        await realtimeV2.removeAllChannels()
    }
}

/// Cross-platform façade for the Supabase Realtime client.
///
/// This is a Skip wrapper around supabase-kt's `Realtime` plugin. On iOS the
/// supabase-swift `RealtimeClientV2` is used directly via `@_exported import Supabase`.
public final class RealtimeClientV2 {
    fileprivate let realtime: io.github.jan.supabase.realtime.Realtime

    init(realtime: io.github.jan.supabase.realtime.Realtime) {
        self.realtime = realtime
    }

    /// Opens the WebSocket connection. Channels do this automatically on first subscribe,
    /// so most callers will not need to call this directly.
    public func connect() async {
        do {
            // SKIP NOWARN
            try await realtime.connect()
        } catch {
            // best-effort; matches supabase-swift's non-throwing surface
        }
    }

    /// Closes the WebSocket connection.
    public func disconnect() {
        realtime.disconnect()
    }

    /// Creates (or returns the existing) channel for `topic`. You must call
    /// ``RealtimeChannelV2/subscribe()`` to start receiving events.
    public func channel(_ topic: String) -> RealtimeChannelV2 {
        let kt = realtime.channel(topic) {
            // default configuration; no broadcast/presence customization
        }
        return RealtimeChannelV2(channel: kt)
    }

    public func removeChannel(_ channel: RealtimeChannelV2) async {
        do {
            // SKIP NOWARN
            try await realtime.removeChannel(channel.channel)
        } catch {
            // swallow
        }
    }

    public func removeAllChannels() async {
        do {
            // SKIP NOWARN
            try await realtime.removeAllChannels()
        } catch {
            // swallow
        }
    }
}

/// Cross-platform Realtime channel. Mirrors the surface of supabase-swift's `RealtimeChannelV2`
/// for the most common operations: subscribe/unsubscribe, postgres changes, and broadcast send.
public final class RealtimeChannelV2 {
    fileprivate let channel: io.github.jan.supabase.realtime.RealtimeChannel

    init(channel: io.github.jan.supabase.realtime.RealtimeChannel) {
        self.channel = channel
    }

    /// The channel topic, without supabase-kt's internal `realtime:` prefix.
    public var topic: String {
        let t = channel.topic
        if t.hasPrefix("realtime:") {
            return String(t.dropFirst(9))
        }
        return t
    }

    /// Subscribes the channel and starts delivering events.
    public func subscribe() async {
        do {
            // SKIP NOWARN
            try await channel.subscribe()
        } catch {
            // matches supabase-swift's non-throwing surface
        }
    }

    /// Unsubscribes the channel.
    public func unsubscribe() async {
        do {
            // SKIP NOWARN
            try await channel.unsubscribe()
        } catch {
            // swallow
        }
    }

    /// Broadcasts a message to all subscribers of this channel.
    public func broadcast(event: String, message: [String: AnyJSON]) async throws {
        // SKIP NOWARN
        try await channel.broadcast(event, dict2JsonObject(message)!)
    }

    /// Subscribes to all postgres change events on a table.
    ///
    /// - Parameters:
    ///   - type: Always `AnyAction.self`. The parameter exists to mirror the
    ///     supabase-swift overload signature; typed (`InsertAction.self` etc.)
    ///     overloads are not yet provided on Android — switch on the delivered
    ///     `AnyAction` instead.
    ///   - schema: The database schema. Defaults to `"public"`.
    ///   - table: Optional table name; when `nil`, all tables in the schema are observed.
    ///   - filter: Optional raw filter string. **Not yet wired through on Android.**
    ///   - callback: Called for every received change.
    /// - Returns: A subscription handle whose `unsubscribe()` stops delivery.
    @discardableResult
    public func onPostgresChange(_ type: AnyAction.Type, schema: String = "public", table: String? = nil, filter: String? = nil, callback: @escaping (AnyAction) -> Void) -> RealtimeSubscription {
        let flow = RealtimeFlowHelper.anyChangeFlow(channel: channel, schema: schema, table: table)
        return startSubscription(flow: flow) { action in
            if let converted = convertAnyAction(action) {
                callback(converted)
            }
        }
    }
}

/// Handle returned by `onPostgresChange` and friends. Calling `cancel()` cancels
/// the background coroutine that's collecting the Kotlin Flow.
///
/// On iOS, supabase-swift exposes the equivalent type as `RealtimeSubscription`
/// (a typealias for `ObservationToken`), which also has `cancel()`. Prefer
/// `cancel()` in cross-platform code; `unsubscribe()` is an Android-only alias.
public final class RealtimeSubscription: @unchecked Sendable {
    fileprivate let job: kotlinx.coroutines.Job

    init(job: kotlinx.coroutines.Job) {
        self.job = job
    }

    /// Stops delivering events for this subscription. Matches supabase-swift's
    /// `ObservationToken.cancel()` shape.
    public func cancel() {
        job.cancel()
    }

    /// Android-only alias for `cancel()`. Not available on iOS — use `cancel()` in
    /// code that must run on both platforms.
    public func unsubscribe() {
        job.cancel()
    }
}

/// A column in a postgres change event.
public struct Column: Hashable, Sendable {
    public let name: String
    public let type: String

    public init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}

/// Marker protocol for postgres change actions. Mirrors supabase-swift's `PostgresAction`.
public protocol PostgresAction: Sendable {
}

public protocol HasRecord {
    var record: [String: AnyJSON] { get }
}

public protocol HasOldRecord {
    var oldRecord: [String: AnyJSON] { get }
}

public struct InsertAction: PostgresAction, HasRecord, Sendable {
    public let columns: [Column]
    public let commitTimestamp: Date
    public let record: [String: AnyJSON]

    public init(columns: [Column], commitTimestamp: Date, record: [String: AnyJSON]) {
        self.columns = columns
        self.commitTimestamp = commitTimestamp
        self.record = record
    }
}

public struct UpdateAction: PostgresAction, HasRecord, HasOldRecord, Sendable {
    public let columns: [Column]
    public let commitTimestamp: Date
    public let record: [String: AnyJSON]
    public let oldRecord: [String: AnyJSON]

    public init(columns: [Column], commitTimestamp: Date, record: [String: AnyJSON], oldRecord: [String: AnyJSON]) {
        self.columns = columns
        self.commitTimestamp = commitTimestamp
        self.record = record
        self.oldRecord = oldRecord
    }
}

public struct DeleteAction: PostgresAction, HasOldRecord, Sendable {
    public let columns: [Column]
    public let commitTimestamp: Date
    public let oldRecord: [String: AnyJSON]

    public init(columns: [Column], commitTimestamp: Date, oldRecord: [String: AnyJSON]) {
        self.columns = columns
        self.commitTimestamp = commitTimestamp
        self.oldRecord = oldRecord
    }
}

/// Sum type for an arbitrary postgres change action.
public enum AnyAction: PostgresAction, Sendable {
    case insert(InsertAction)
    case update(UpdateAction)
    case delete(DeleteAction)
}

// MARK: - Bridging helpers

/// Launches a coroutine that collects `flow` and forwards each emission to `onEach`.
/// The returned subscription's `unsubscribe()` cancels the coroutine.
private func startSubscription<T>(flow: kotlinx.coroutines.flow.Flow<T>, onEach: @escaping (T) -> Void) -> RealtimeSubscription {
    let job = Job()
    GlobalScope.launch(job) {
        flow.collect { value in
            onEach(value)
        }
    }
    return RealtimeSubscription(job: job)
}

private func convertColumn(_ c: io.github.jan.supabase.realtime.Column) -> Column {
    Column(name: c.name, type: c.type)
}

// SKIP INSERT: @OptIn(kotlin.time.ExperimentalTime::class)
private func convertInsertAction(_ a: io.github.jan.supabase.realtime.PostgresAction.Insert) -> InsertAction {
    let cols = Array(a.columns).map { convertColumn($0) }
    let date = instant2date(a.commitTimestamp) ?? Date()
    return InsertAction(
        columns: cols,
        commitTimestamp: date,
        record: jsonObject2Dict(a.record) ?? [:]
    )
}

// SKIP INSERT: @OptIn(kotlin.time.ExperimentalTime::class)
private func convertUpdateAction(_ a: io.github.jan.supabase.realtime.PostgresAction.Update) -> UpdateAction {
    let cols = Array(a.columns).map { convertColumn($0) }
    let date = instant2date(a.commitTimestamp) ?? Date()
    return UpdateAction(
        columns: cols,
        commitTimestamp: date,
        record: jsonObject2Dict(a.record) ?? [:],
        oldRecord: jsonObject2Dict(a.oldRecord) ?? [:]
    )
}

// SKIP INSERT: @OptIn(kotlin.time.ExperimentalTime::class)
private func convertDeleteAction(_ a: io.github.jan.supabase.realtime.PostgresAction.Delete) -> DeleteAction {
    let cols = Array(a.columns).map { convertColumn($0) }
    let date = instant2date(a.commitTimestamp) ?? Date()
    return DeleteAction(
        columns: cols,
        commitTimestamp: date,
        oldRecord: jsonObject2Dict(a.oldRecord) ?? [:]
    )
}

private func convertAnyAction(_ a: io.github.jan.supabase.realtime.PostgresAction) -> AnyAction? {
    if let i = a as? io.github.jan.supabase.realtime.PostgresAction.Insert {
        return .insert(convertInsertAction(i))
    }
    if let u = a as? io.github.jan.supabase.realtime.PostgresAction.Update {
        return .update(convertUpdateAction(u))
    }
    if let d = a as? io.github.jan.supabase.realtime.PostgresAction.Delete {
        return .delete(convertDeleteAction(d))
    }
    return nil
}

#endif

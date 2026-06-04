// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
package skip.supabase

import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.PostgresChangeFilter
import io.github.jan.supabase.realtime.RealtimeChannel
import io.github.jan.supabase.realtime.postgresChangeFlow
import kotlinx.coroutines.flow.Flow

/// Bridges supabase-kt's reified `postgresChangeFlow<T>` extension into a non-reified
/// surface that the Skip-transpiled Swift wrapper can call. The internal
/// `postgresChangeFlowInternal` is `@PublishedApi internal` and not callable from
/// other modules, so we go through the public reified extension here.
internal object RealtimeFlowHelper {

    fun anyChangeFlow(channel: RealtimeChannel, schema: String, table: String?): Flow<PostgresAction> =
        channel.postgresChangeFlow<PostgresAction>(schema) {
            table?.let { this.table = it }
        }

    fun insertChangeFlow(channel: RealtimeChannel, schema: String, table: String?): Flow<PostgresAction.Insert> =
        channel.postgresChangeFlow<PostgresAction.Insert>(schema) {
            table?.let { this.table = it }
        }

    fun updateChangeFlow(channel: RealtimeChannel, schema: String, table: String?): Flow<PostgresAction.Update> =
        channel.postgresChangeFlow<PostgresAction.Update>(schema) {
            table?.let { this.table = it }
        }

    fun deleteChangeFlow(channel: RealtimeChannel, schema: String, table: String?): Flow<PostgresAction.Delete> =
        channel.postgresChangeFlow<PostgresAction.Delete>(schema) {
            table?.let { this.table = it }
        }
}

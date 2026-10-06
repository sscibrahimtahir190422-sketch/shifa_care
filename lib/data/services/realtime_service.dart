import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';


class RealtimeService {
  RealtimeService(this._client);

  final SupabaseClient _client;

  RealtimeChannel listen({
    required String table,
    required String column,
    required String value,
    required void Function() onChange,
  }) {
    Timer? debounce;
    final channel = _client.channel(
      'rt-$table-$value-${DateTime.now().microsecondsSinceEpoch}',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: column,
            value: value,
          ),
          callback: (_) {

            debounce?.cancel();
            debounce = Timer(const Duration(milliseconds: 250), onChange);
          },
        )
        .subscribe();

    return channel;
  }

  Future<void> stop(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}

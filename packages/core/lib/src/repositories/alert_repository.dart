import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alert.dart';

class AlertRepository {
  AlertRepository(this._client);
  final SupabaseClient _client;

  Future<List<Alert>> list(String memberId) async {
    final rows = await _client
        .from('alerts')
        .select()
        .eq('member_id', memberId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Alert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Flux temps réel des alertes d'un membre (badge de notifications).
  Stream<List<Alert>> watch(String memberId) {
    return _client
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('member_id', memberId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Alert.fromJson).toList());
  }

  Future<void> markRead(String id) async {
    await _client.from('alerts').update({'read': true}).eq('id', id);
  }

  Future<void> markAllRead(String memberId) async {
    await _client
        .from('alerts')
        .update({'read': true})
        .eq('member_id', memberId)
        .eq('read', false);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recurring_template.dart';

class RecurringRepository {
  RecurringRepository(this._client);
  final SupabaseClient _client;

  Future<List<RecurringTemplate>> list({String? memberId}) async {
    var query = _client.from('recurring_templates').select();
    if (memberId != null) query = query.eq('member_id', memberId);
    final rows = await query.order('label');
    return (rows as List)
        .map((e) => RecurringTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecurringTemplate> upsert(
      RecurringTemplate template, String familyId) async {
    final row = await _client
        .from('recurring_templates')
        .upsert(template.toUpsert(familyId))
        .select()
        .single();
    return RecurringTemplate.fromJson(row);
  }

  Future<void> setActive(String id, bool active) async {
    await _client
        .from('recurring_templates')
        .update({'active': active}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('recurring_templates').delete().eq('id', id);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._client);
  final SupabaseClient _client;

  /// Liste filtrée. Les bornes de période sont exprimées en dates incluses.
  Future<List<Expense>> list({
    String? memberId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client.from('expenses').select();
    if (memberId != null) query = query.eq('member_id', memberId);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (from != null) query = query.gte('spent_at', from.toIso8601String());
    if (to != null) query = query.lte('spent_at', to.toIso8601String());
    final rows = await query.order('spent_at', ascending: false);
    return (rows as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> add(Expense expense, String familyId, String memberId) async {
    final row = await _client
        .from('expenses')
        .insert(expense.toInsert(familyId, memberId))
        .select()
        .single();
    return Expense.fromJson(row);
  }

  Future<void> update(Expense expense) async {
    await _client.from('expenses').update({
      'category_id': expense.categoryId,
      'amount': expense.amount,
      'note': expense.note,
      'spent_at': expense.spentAt.toIso8601String(),
      'type': expense.type.name,
      if (expense.frequency != null) 'frequency': expense.frequency!.name else 'frequency': null,
      if (expense.frequencyDay != null) 'frequency_day': expense.frequencyDay else 'frequency_day': null,
    }).eq('id', expense.id);
  }

  Future<void> delete(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  /// Flux temps réel des dépenses d'un membre (utilisé par le dashboard mobile).
  Stream<List<Expense>> watchForMember(String memberId) {
    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('member_id', memberId)
        .order('spent_at', ascending: false)
        .map((rows) => rows.map(Expense.fromJson).toList());
  }
}

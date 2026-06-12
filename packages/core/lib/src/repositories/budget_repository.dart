import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/budget.dart';
import '../utils/period.dart';

class BudgetRepository {
  BudgetRepository(this._client);
  final SupabaseClient _client;

  Future<List<Budget>> listForPeriod(
    DateTime period, {
    String? memberId,
  }) async {
    var query =
        _client.from('budgets').select().eq('period', Period.toSql(period));
    if (memberId != null) query = query.eq('member_id', memberId);
    final rows = await query;
    return (rows as List)
        .map((e) => Budget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée ou met à jour une enveloppe (unicité sur member/categorie/période).
  Future<Budget> upsert(Budget budget, String familyId) async {
    final row = await _client
        .from('budgets')
        .upsert(
          budget.toUpsert(familyId),
          onConflict: 'member_id,category_id,period',
        )
        .select()
        .single();
    return Budget.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('budgets').delete().eq('id', id);
  }

  /// Recopie les budgets d'un mois vers le mois suivant (RPC côté base pour
  /// rester transactionnel).
  Future<void> copyToNextMonth(DateTime fromPeriod) async {
    await _client.rpc('copy_budgets_to_next_month', params: {
      'p_from_period': Period.toSql(fromPeriod),
    });
  }
}

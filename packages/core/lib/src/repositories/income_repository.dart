import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/income.dart';
import '../utils/period.dart';

class IncomeRepository {
  IncomeRepository(this._client);
  final SupabaseClient _client;

  Future<List<Income>> listForPeriod(DateTime period) async {
    final rows = await _client
        .from('incomes')
        .select()
        .eq('period', Period.toSql(period))
        .order('created_at');
    return (rows as List)
        .map((e) => Income.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Income> add(Income income, String familyId) async {
    final row = await _client
        .from('incomes')
        .insert(income.toInsert(familyId))
        .select()
        .single();
    return Income.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('incomes').delete().eq('id', id);
  }

  /// Total des revenus d'un mois.
  Future<double> totalForPeriod(DateTime period) async {
    final list = await listForPeriod(period);
    return list.fold<double>(0, (sum, i) => sum + i.amount);
  }
}

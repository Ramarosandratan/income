import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/savings_goal.dart';

class SavingsRepository {
  SavingsRepository(this._client);
  final SupabaseClient _client;

  Future<List<SavingsGoal>> list({String? memberId}) async {
    final rows = await _client.from('savings_goals').select().order('created_at');
    final goals = (rows as List)
        .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
        .toList();
    if (memberId == null) return goals;
    // Objectifs du membre + objectifs familiaux (member_id null).
    return goals
        .where((g) => g.memberId == null || g.memberId == memberId)
        .toList();
  }

  Future<SavingsGoal> upsert(SavingsGoal goal, String familyId) async {
    final row = await _client
        .from('savings_goals')
        .upsert(goal.toUpsert(familyId))
        .select()
        .single();
    return SavingsGoal.fromJson(row);
  }

  /// Ajoute une contribution au montant déjà épargné.
  Future<void> contribute(String id, double amount) async {
    await _client.rpc('add_savings_contribution', params: {
      'p_goal_id': id,
      'p_amount': amount,
    });
  }

  Future<void> delete(String id) async {
    await _client.from('savings_goals').delete().eq('id', id);
  }
}

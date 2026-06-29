import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

/// Providers de données agrégées pour l'app desktop (toute la famille).
/// Les données « par période » suivent [selectedPeriodProvider].

final membersProvider = FutureProvider<List<Profile>>(
    (ref) => ref.watch(profileRepositoryProvider).listMembers());

final categoriesProvider = FutureProvider<List<Category>>(
    (ref) => ref.watch(categoryRepositoryProvider).list());

({DateTime from, DateTime to}) _monthBounds(DateTime period) {
  final from = DateTime(period.year, period.month, 1);
  final to = DateTime(period.year, period.month + 1, 1)
      .subtract(const Duration(seconds: 1));
  return (from: from, to: to);
}

final periodExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final b = _monthBounds(period);
  return ref.watch(expenseRepositoryProvider).list(from: b.from, to: b.to);
});

final periodBudgetsProvider = FutureProvider<List<Budget>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(budgetRepositoryProvider).listForPeriod(period);
});

final periodIncomesProvider = FutureProvider<List<Income>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(incomeRepositoryProvider).listForPeriod(period);
});

/// Synthèse par membre (alloué / dépensé) pour le mois sélectionné.
final memberSummariesProvider =
    FutureProvider<List<MemberBudgetSummary>>((ref) async {
  final members = await ref.watch(membersProvider.future);
  final budgets = await ref.watch(periodBudgetsProvider.future);
  final expenses = await ref.watch(periodExpensesProvider.future);
  final calc = ref.watch(budgetCalculatorProvider);
  return members.map((m) {
    return calc.summarize(
      memberId: m.id,
      budgets: budgets.where((b) => b.memberId == m.id).toList(),
      expenses: expenses.where((e) => e.memberId == m.id).toList(),
    );
  }).toList();
});

final savingsProvider = FutureProvider<List<SavingsGoal>>(
    (ref) => ref.watch(savingsRepositoryProvider).list());

/// Alertes de toute la famille, en temps réel (pour le maître).
final familyAlertsProvider = StreamProvider<List<Alert>>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  if (profile == null) return Stream.value(const <Alert>[]);
  // watchForFamily() utilise la RLS pour filtrer par family_id du master.
  return ref.watch(alertRepositoryProvider).watchForFamily();
});

/// Nombre d'alertes non lues (pour le badge de navigation).
final unreadFamilyAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(familyAlertsProvider).valueOrNull ?? const [];
  return alerts.where((a) => !a.read).length;
});

/// Mois précédent dérivé de la période sélectionnée.
final previousPeriodProvider = Provider<DateTime>(
    (ref) => Period.previous(ref.watch(selectedPeriodProvider)));

final previousPeriodExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final period = ref.watch(previousPeriodProvider);
  final b = _monthBounds(period);
  return ref.watch(expenseRepositoryProvider).list(from: b.from, to: b.to);
});

final previousPeriodIncomesProvider = FutureProvider<List<Income>>((ref) {
  final period = ref.watch(previousPeriodProvider);
  return ref.watch(incomeRepositoryProvider).listForPeriod(period);
});

/// Invalide tous les providers dépendant des données (après une mutation).
void refreshAll(WidgetRef ref) {
  ref.invalidate(previousPeriodExpensesProvider);
  ref.invalidate(previousPeriodIncomesProvider);
  ref.invalidate(periodExpensesProvider);
  ref.invalidate(periodBudgetsProvider);
  ref.invalidate(periodIncomesProvider);
  ref.invalidate(memberSummariesProvider);
  ref.invalidate(membersProvider);
}

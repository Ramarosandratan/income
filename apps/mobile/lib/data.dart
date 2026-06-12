import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

/// Providers centrés sur le membre connecté.

/// Id du membre connecté.
final myIdProvider = Provider<String?>(
    (ref) => ref.watch(authServiceProvider).currentUser?.id);

final categoriesProvider = FutureProvider<List<Category>>(
    (ref) => ref.watch(categoryRepositoryProvider).list());

/// Dépenses du membre en temps réel (toutes périodes ; filtrées à l'affichage).
final myExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final id = ref.watch(myIdProvider);
  if (id == null) return const Stream.empty();
  return ref.watch(expenseRepositoryProvider).watchForMember(id);
});

/// Dépenses du mois sélectionné (dérivé du flux temps réel).
final myMonthExpensesProvider = Provider<List<Expense>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final all = ref.watch(myExpensesStreamProvider).valueOrNull ?? const [];
  return all
      .where((e) =>
          e.spentAt.year == period.year && e.spentAt.month == period.month)
      .toList();
});

/// Budgets du membre pour le mois.
final myBudgetsProvider = FutureProvider<List<Budget>>((ref) {
  final id = ref.watch(myIdProvider);
  final period = ref.watch(selectedPeriodProvider);
  if (id == null) return Future.value(const []);
  return ref
      .watch(budgetRepositoryProvider)
      .listForPeriod(period, memberId: id);
});

/// Synthèse « reste à dépenser » du membre pour le mois.
final mySummaryProvider = Provider<MemberBudgetSummary?>((ref) {
  final id = ref.watch(myIdProvider);
  if (id == null) return null;
  final budgets = ref.watch(myBudgetsProvider).valueOrNull ?? const [];
  final expenses = ref.watch(myMonthExpensesProvider);
  return ref.watch(budgetCalculatorProvider).summarize(
        memberId: id,
        budgets: budgets,
        expenses: expenses,
      );
});

/// Alertes du membre, en temps réel.
final myAlertsProvider = StreamProvider<List<Alert>>((ref) {
  final id = ref.watch(myIdProvider);
  if (id == null) return const Stream.empty();
  return ref.watch(alertRepositoryProvider).watch(id);
});

final unreadAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(myAlertsProvider).valueOrNull ?? const [];
  return alerts.where((a) => !a.read).length;
});

/// Objectifs d'épargne visibles par le membre (les siens + familiaux).
final mySavingsProvider = FutureProvider<List<SavingsGoal>>((ref) {
  final id = ref.watch(myIdProvider);
  return ref.watch(savingsRepositoryProvider).list(memberId: id);
});

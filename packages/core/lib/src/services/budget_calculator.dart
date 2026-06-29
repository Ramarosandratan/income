import '../models/budget.dart';
import '../models/budget_summary.dart';
import '../models/expense.dart';

/// Logique métier pure (sans I/O) de rapprochement budgets ↔ dépenses.
/// Testable unitairement, partagée par les deux apps.
class BudgetCalculator {
  const BudgetCalculator();

  /// Calcule la synthèse d'un membre à partir de ses enveloppes et dépenses
  /// du mois.
  ///
  /// Règles :
  /// - une enveloppe sans catégorie (categoryId null) couvre toutes les
  ///   dépenses non couvertes par une enveloppe catégorisée ;
  /// - le total alloué est la somme de toutes les enveloppes du membre ;
  /// - le total dépensé est la somme de toutes ses dépenses du mois.
  MemberBudgetSummary summarize({
    required String memberId,
    required List<Budget> budgets,
    required List<Expense> expenses,
  }) {
    final categorized =
        budgets.where((b) => b.categoryId != null).toList(growable: false);
    final categorizedIds = categorized.map((b) => b.categoryId).toSet();

    double spentFor(String? categoryId) => expenses
        .where((e) => e.categoryId == categoryId)
        .fold<double>(0, (s, e) => s + e.amount);

    final lines = <BudgetLine>[];

    // Lignes par catégorie budgétée.
    for (final b in categorized) {
      lines.add(BudgetLine(
        categoryId: b.categoryId,
        allocated: b.amount,
        spent: spentFor(b.categoryId),
      ));
    }

    // Ligne globale : enveloppes sans catégorie + dépenses hors catégories
    // budgétées.
    final globalAllocated = budgets
        .where((b) => b.categoryId == null)
        .fold<double>(0, (s, b) => s + b.amount);
    final uncategorizedSpent = expenses
        .where((e) => !categorizedIds.contains(e.categoryId))
        .fold<double>(0, (s, e) => s + e.amount);
    if (globalAllocated > 0 || uncategorizedSpent > 0) {
      lines.add(BudgetLine(
        categoryId: null,
        allocated: globalAllocated,
        spent: uncategorizedSpent,
      ));
    }

    final totalAllocated = budgets.fold<double>(0, (s, b) => s + b.amount);
    final totalSpent = expenses.fold<double>(0, (s, e) => s + e.amount);

    return MemberBudgetSummary(
      memberId: memberId,
      totalAllocated: totalAllocated,
      totalSpent: totalSpent,
      lines: lines,
    );
  }

  /// Total des dépenses par catégorie (pour les graphiques camembert).
  Map<String, double> spentByCategory(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      final key = e.categoryId ?? '__none__';
      map[key] = (map[key] ?? 0) + e.amount;
    }
    return map;
  }
}

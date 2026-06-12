/// Synthèse de consommation d'une enveloppe : alloué vs dépensé.
class BudgetLine {
  const BudgetLine({
    required this.categoryId,
    required this.allocated,
    required this.spent,
  });

  /// null = enveloppe globale (toutes catégories confondues).
  final String? categoryId;
  final double allocated;
  final double spent;

  double get remaining => allocated - spent;
  double get ratio => allocated <= 0 ? 0 : (spent / allocated);
  bool get isExceeded => spent > allocated && allocated > 0;
  bool get isWarning => ratio >= 0.8 && !isExceeded;
}

/// Synthèse complète d'un membre pour un mois.
class MemberBudgetSummary {
  const MemberBudgetSummary({
    required this.memberId,
    required this.totalAllocated,
    required this.totalSpent,
    required this.lines,
  });

  final String memberId;
  final double totalAllocated;
  final double totalSpent;
  final List<BudgetLine> lines;

  double get remaining => totalAllocated - totalSpent;
  double get ratio => totalAllocated <= 0 ? 0 : (totalSpent / totalAllocated);
}

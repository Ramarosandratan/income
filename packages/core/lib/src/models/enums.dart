// Énumérations partagées, sérialisées en chaînes correspondant aux types SQL.

enum UserRole {
  master,
  member;

  static UserRole fromString(String v) =>
      UserRole.values.firstWhere((e) => e.name == v, orElse: () => UserRole.member);
}

/// Nature d'une catégorie ou d'un modèle récurrent.
enum EntryKind {
  expense,
  income;

  static EntryKind fromString(String v) =>
      EntryKind.values.firstWhere((e) => e.name == v, orElse: () => EntryKind.expense);
}

/// Type d'une dépense saisie.
enum ExpenseType {
  daily,
  monthly,
  fixed;

  static ExpenseType fromString(String v) =>
      ExpenseType.values.firstWhere((e) => e.name == v, orElse: () => ExpenseType.daily);

  String get labelFr => switch (this) {
        ExpenseType.daily => 'Journalière',
        ExpenseType.monthly => 'Mensuelle',
        ExpenseType.fixed => 'Fixe',
      };
}

/// Type d'une enveloppe budgétaire.
enum BudgetType {
  budget,
  fixed;

  static BudgetType fromString(String v) =>
      BudgetType.values.firstWhere((e) => e.name == v, orElse: () => BudgetType.budget);
}

/// Fréquence d'un modèle récurrent.
enum Frequency {
  weekly,
  monthly;

  static Frequency fromString(String v) =>
      Frequency.values.firstWhere((e) => e.name == v, orElse: () => Frequency.monthly);
}

/// Type d'alerte.
enum AlertKind {
  budgetWarning, // seuil approché (ex. 80 %)
  budgetExceeded; // budget dépassé

  static AlertKind fromString(String v) => switch (v) {
        'budget_warning' => AlertKind.budgetWarning,
        'budget_exceeded' => AlertKind.budgetExceeded,
        _ => AlertKind.budgetWarning,
      };

  String get wire => switch (this) {
        AlertKind.budgetWarning => 'budget_warning',
        AlertKind.budgetExceeded => 'budget_exceeded',
      };
}

// Énumérations partagées, sérialisées en chaînes correspondant aux types SQL.

enum UserRole {
  master,
  member;

  static UserRole fromString(String v) => UserRole.values
      .firstWhere((e) => e.name == v, orElse: () => UserRole.member);
}

/// Nature d'une catégorie ou d'un modèle récurrent.
enum EntryKind {
  expense,
  income;

  static EntryKind fromString(String v) => EntryKind.values
      .firstWhere((e) => e.name == v, orElse: () => EntryKind.expense);
}

/// Type d'une dépense saisie.
enum ExpenseType {
  daily,
  monthly,
  fixed;

  static ExpenseType fromString(String v) => ExpenseType.values
      .firstWhere((e) => e.name == v, orElse: () => ExpenseType.daily);

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

  static BudgetType fromString(String v) => BudgetType.values
      .firstWhere((e) => e.name == v, orElse: () => BudgetType.budget);
}

/// Fréquence d'un revenu, d'un modèle récurrent ou d'une dépense.
enum Frequency {
  daily,
  weekly,
  monthly,
  yearly;

  static Frequency fromString(String v) => Frequency.values
      .firstWhere((e) => e.name == v, orElse: () => Frequency.monthly);

  String get labelFr => switch (this) {
        Frequency.daily => 'Tous les jours',
        Frequency.weekly => 'Hebdomadaire',
        Frequency.monthly => 'Mensuel',
        Frequency.yearly => 'Annuel',
      };

  /// Libellé court pour l'affichage dans les tableaux.
  String get shortLabel => switch (this) {
        Frequency.daily => 'Quotidien',
        Frequency.weekly => 'Hebdo',
        Frequency.monthly => 'Mensuel',
        Frequency.yearly => 'Annuel',
      };
}

/// Utilitaires pour les énumérations.
class EnumUtils {
  /// Libellé du jour de la semaine (1=lundi … 7=dimanche).
  static String dayOfWeekLabel(int day) => switch (day) {
        1 => 'lun',
        2 => 'mar',
        3 => 'mer',
        4 => 'jeu',
        5 => 'ven',
        6 => 'sam',
        7 => 'dim',
        _ => 'j$day',
      };
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

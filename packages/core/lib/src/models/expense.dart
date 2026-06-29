import 'enums.dart';

/// Une dépense saisie par un membre.
class Expense {
  const Expense({
    required this.id,
    required this.familyId,
    required this.memberId,
    this.categoryId,
    required this.amount,
    this.note,
    required this.spentAt,
    this.type = ExpenseType.daily,
    this.frequency,
    this.frequencyDay,
    this.recurringTemplateId,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String memberId;
  final String? categoryId;
  final double amount;
  final String? note;
  final DateTime spentAt;
  final ExpenseType type;

  /// Fréquence de récurrence (hebdomadaire/mensuel/annuel).
  final Frequency? frequency;

  /// Jour configuré pour la fréquence (voir RecurringTemplate.frequencyDay).
  final int? frequencyDay;

  /// ID du template récurrent à l'origine de cette dépense (si applicable).
  final String? recurringTemplateId;
  final DateTime createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        memberId: json['member_id'] as String,
        categoryId: json['category_id'] as String?,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String?,
        spentAt: DateTime.parse(json['spent_at'] as String),
        type: ExpenseType.fromString(json['type'] as String),
        frequency: json['frequency'] != null
            ? Frequency.fromString(json['frequency'] as String)
            : null,
        frequencyDay: json['frequency_day'] as int?,
        recurringTemplateId: json['recurring_template_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsert(String familyId, String memberId) => {
        'family_id': familyId,
        'member_id': memberId,
        'category_id': categoryId,
        'amount': amount,
        'note': note,
        'spent_at': spentAt.toIso8601String(),
        'type': type.name,
        if (frequency != null) 'frequency': frequency!.name,
        if (frequencyDay != null) 'frequency_day': frequencyDay,
        if (recurringTemplateId != null)
          'recurring_template_id': recurringTemplateId,
      };

  Expense copyWith({
    String? categoryId,
    double? amount,
    String? note,
    DateTime? spentAt,
    ExpenseType? type,
    Frequency? frequency,
    int? frequencyDay,
  }) =>
      Expense(
        id: id,
        familyId: familyId,
        memberId: memberId,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        spentAt: spentAt ?? this.spentAt,
        type: type ?? this.type,
        frequency: frequency ?? this.frequency,
        frequencyDay: frequencyDay ?? this.frequencyDay,
        recurringTemplateId: recurringTemplateId,
        createdAt: createdAt,
      );

  /// Libellé lisible de la fréquence, ex. « Mensuel le 15 » ou « Hebdo lun ».
  String get frequencyLabel {
    if (frequency == null) return '—';
    if (frequencyDay == null) return frequency!.labelFr;
    return switch (frequency!) {
      Frequency.weekly => '${frequency!.shortLabel} ${EnumUtils.dayOfWeekLabel(frequencyDay!)}',
      Frequency.monthly => '${frequency!.labelFr} le $frequencyDay',
      Frequency.yearly => '${frequency!.labelFr} le $frequencyDay/${spentAt.month}',
    };
  }
}

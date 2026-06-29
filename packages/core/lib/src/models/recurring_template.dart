import 'enums.dart';

/// Modèle de dépense (ou revenu) récurrent. Une Edge Function planifiée génère
/// les écritures correspondantes lorsque `nextRun` est atteint.
class RecurringTemplate {
  const RecurringTemplate({
    required this.id,
    required this.familyId,
    required this.memberId,
    this.categoryId,
    required this.label,
    required this.amount,
    this.kind = EntryKind.expense,
    this.frequency = Frequency.monthly,
    this.frequencyDay,
    this.daysOfWeek,
    required this.nextRun,
    this.active = true,
  });

  final String id;
  final String familyId;
  final String memberId;
  final String? categoryId;
  final String label;
  final double amount;
  final EntryKind kind;
  final Frequency frequency;

  /// Jour configuré pour la fréquence :
  /// - weekly → 1=lundi … 7=dimanche
  /// - monthly → 1…31 (jour du mois)
  /// - yearly → 1…31 (jour du mois, mois = next_run)
  final int? frequencyDay;

  /// Jours de la semaine sélectionnés (1=lundi … 7=dimanche).
  /// Utilisé pour "tous les jours" ou "jours sélectionnés".
  final List<int>? daysOfWeek;

  final DateTime nextRun;
  final bool active;

  factory RecurringTemplate.fromJson(Map<String, dynamic> json) =>
      RecurringTemplate(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        memberId: json['member_id'] as String,
        categoryId: json['category_id'] as String?,
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        kind: EntryKind.fromString(json['kind'] as String),
        frequency: Frequency.fromString(json['frequency'] as String),
        frequencyDay: json['frequency_day'] as int?,
        daysOfWeek: json['days_of_week'] != null
            ? (json['days_of_week'] as List).cast<int>()
            : null,
        nextRun: DateTime.parse(json['next_run'] as String),
        active: json['active'] as bool? ?? true,
      );

  Map<String, dynamic> toUpsert(String familyId) => {
        'family_id': familyId,
        'member_id': memberId,
        'category_id': categoryId,
        'label': label,
        'amount': amount,
        'kind': kind.name,
        'frequency': frequency.name,
        if (frequencyDay != null) 'frequency_day': frequencyDay,
        if (daysOfWeek != null) 'days_of_week': daysOfWeek,
        'next_run': nextRun.toIso8601String(),
        'active': active,
      };

  /// Libellé lisible de la fréquence, ex. « Mensuel le 15 » ou « Hebdo lun ».
  String get frequencyLabel {
    final base = frequency.labelFr;
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      return '${frequency.shortLabel} ${daysOfWeek!.map(EnumUtils.dayOfWeekLabel).join(', ')}';
    }
    if (frequencyDay == null) return base;
    return switch (frequency) {
      Frequency.daily => base,
      Frequency.weekly =>
        '${frequency.shortLabel} ${EnumUtils.dayOfWeekLabel(frequencyDay!)}',
      Frequency.monthly => '$base le $frequencyDay',
      Frequency.yearly => '$base le $frequencyDay/${nextRun.month}',
    };
  }
}

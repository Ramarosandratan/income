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
        'next_run': nextRun.toIso8601String(),
        'active': active,
      };
}

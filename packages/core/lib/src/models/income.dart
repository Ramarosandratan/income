import '../models/enums.dart';
import '../utils/period.dart';

/// Un revenu, rattaché au foyer (memberId null) ou à un membre précis.
class Income {
  const Income({
    required this.id,
    required this.familyId,
    this.memberId,
    required this.source,
    required this.amount,
    required this.period,
    required this.frequency,
    this.frequencyDay,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String? memberId;
  final String source;
  final double amount;
  final DateTime period; // 1er du mois
  final Frequency frequency;

  /// Jour configuré pour la fréquence :
  /// - weekly → 1=lundi … 7=dimanche
  /// - monthly → 1…31 (jour du mois)
  /// - yearly → 1…31 (jour du mois, mois = period)
  final int? frequencyDay;

  final DateTime createdAt;

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        memberId: json['member_id'] as String?,
        source: json['source'] as String,
        amount: (json['amount'] as num).toDouble(),
        period: Period.fromSql(json['period'] as String),
        frequency:
            Frequency.fromString(json['frequency'] as String? ?? 'monthly'),
        frequencyDay: json['frequency_day'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsert(String familyId) => {
        'family_id': familyId,
        'member_id': memberId,
        'source': source,
        'amount': amount,
        'period': Period.toSql(period),
        'frequency': frequency.name,
        if (frequencyDay != null) 'frequency_day': frequencyDay,
      };

  /// Libellé lisible de la fréquence.
  String get frequencyLabel {
    if (frequencyDay == null) return frequency.labelFr;
    return switch (frequency) {
      Frequency.daily => frequency.labelFr,
      Frequency.weekly =>
        '${frequency.shortLabel} ${EnumUtils.dayOfWeekLabel(frequencyDay!)}',
      Frequency.monthly => '${frequency.labelFr} le $frequencyDay',
      Frequency.yearly =>
        '${frequency.labelFr} le $frequencyDay/${period.month}',
    };
  }
}

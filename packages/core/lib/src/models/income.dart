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
    this.isRecurring = false,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String? memberId;
  final String source;
  final double amount;
  final DateTime period; // 1er du mois
  final bool isRecurring;
  final DateTime createdAt;

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        memberId: json['member_id'] as String?,
        source: json['source'] as String,
        amount: (json['amount'] as num).toDouble(),
        period: Period.fromSql(json['period'] as String),
        isRecurring: json['is_recurring'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsert(String familyId) => {
        'family_id': familyId,
        'member_id': memberId,
        'source': source,
        'amount': amount,
        'period': Period.toSql(period),
        'is_recurring': isRecurring,
      };
}

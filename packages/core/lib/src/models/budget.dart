import '../utils/period.dart';
import 'enums.dart';

/// Enveloppe budgétaire allouée par le maître à un membre, pour un mois donné.
/// Peut être globale (categoryId null) ou ciblée sur une catégorie.
class Budget {
  const Budget({
    required this.id,
    required this.familyId,
    required this.memberId,
    this.categoryId,
    required this.period,
    required this.amount,
    this.type = BudgetType.budget,
  });

  final String id;
  final String familyId;
  final String memberId;
  final String? categoryId;
  final DateTime period; // 1er du mois
  final double amount;
  final BudgetType type;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        memberId: json['member_id'] as String,
        categoryId: json['category_id'] as String?,
        period: Period.fromSql(json['period'] as String),
        amount: (json['amount'] as num).toDouble(),
        type: BudgetType.fromString(json['type'] as String),
      );

  Map<String, dynamic> toUpsert(String familyId) => {
        'family_id': familyId,
        'member_id': memberId,
        'category_id': categoryId,
        'period': Period.toSql(period),
        'amount': amount,
        'type': type.name,
      };
}

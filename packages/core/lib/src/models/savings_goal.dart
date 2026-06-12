/// Objectif d'épargne, pour la famille (memberId null) ou un membre précis.
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.familyId,
    this.memberId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String? memberId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  bool get isReached => currentAmount >= targetAmount;

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        memberId: json['member_id'] as String?,
        name: json['name'] as String,
        targetAmount: (json['target_amount'] as num).toDouble(),
        currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
        deadline: json['deadline'] == null
            ? null
            : DateTime.parse(json['deadline'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toUpsert(String familyId) => {
        'family_id': familyId,
        'member_id': memberId,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'deadline': deadline?.toIso8601String(),
      };
}

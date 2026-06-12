import 'enums.dart';

/// Alerte de suivi budgétaire destinée à un membre.
class Alert {
  const Alert({
    required this.id,
    required this.memberId,
    required this.kind,
    required this.message,
    this.read = false,
    required this.createdAt,
  });

  final String id;
  final String memberId;
  final AlertKind kind;
  final String message;
  final bool read;
  final DateTime createdAt;

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['id'] as String,
        memberId: json['member_id'] as String,
        kind: AlertKind.fromString(json['kind'] as String),
        message: json['message'] as String,
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

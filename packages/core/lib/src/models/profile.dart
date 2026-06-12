import 'enums.dart';

/// Profil d'un membre de la famille, lié à un compte d'authentification Supabase.
class Profile {
  const Profile({
    required this.id,
    required this.familyId,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id; // = auth.users.id
  final String familyId;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  bool get isMaster => role == UserRole.master;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        fullName: json['full_name'] as String,
        role: UserRole.fromString(json['role'] as String),
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toUpdate() => {
        'full_name': fullName,
        'avatar_url': avatarUrl,
      };
}

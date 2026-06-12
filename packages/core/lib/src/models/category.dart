import 'enums.dart';

/// Catégorie de dépense ou de revenu, partagée au sein de la famille.
class Category {
  const Category({
    required this.id,
    required this.familyId,
    required this.name,
    required this.icon,
    required this.color,
    required this.kind,
  });

  final String id;
  final String familyId;
  final String name;

  /// Nom d'icône Material (ex. "restaurant", "directions_car").
  final String icon;

  /// Couleur encodée en hexadécimal ARGB (ex. "FF4CAF50").
  final String color;
  final EntryKind kind;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'category',
        color: json['color'] as String? ?? 'FF9E9E9E',
        kind: EntryKind.fromString(json['kind'] as String),
      );

  Map<String, dynamic> toInsert(String familyId) => {
        'family_id': familyId,
        'name': name,
        'icon': icon,
        'color': color,
        'kind': kind.name,
      };
}

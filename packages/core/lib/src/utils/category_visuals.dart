import 'package:flutter/material.dart';

/// Conversion des champs « icon » (nom Material) et « color » (hex ARGB) d'une
/// catégorie en objets Flutter. Partagé par les deux apps.
class CategoryVisuals {
  static const Map<String, IconData> _icons = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'sports_esports': Icons.sports_esports,
    'favorite': Icons.favorite,
    'receipt_long': Icons.receipt_long,
    'payments': Icons.payments,
    'shopping_cart': Icons.shopping_cart,
    'school': Icons.school,
    'pets': Icons.pets,
    'category': Icons.category,
  };

  static IconData icon(String name) => _icons[name] ?? Icons.category;

  /// Liste des icônes proposables dans les formulaires.
  static List<MapEntry<String, IconData>> get choices => _icons.entries.toList();

  /// Parse une couleur "AARRGGBB" en Color (gris par défaut si invalide).
  static Color color(String hex) {
    final value = int.tryParse(hex, radix: 16);
    return value == null ? const Color(0xFF9E9E9E) : Color(value);
  }

  static String toHex(Color c) =>
      c.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');
}

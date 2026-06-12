import 'package:flutter/material.dart';

/// Thème de l'app desktop (maître). Tonalité « tableau de bord » sobre.
ThemeData buildDesktopTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1565C0),
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.comfortable,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
  );
}

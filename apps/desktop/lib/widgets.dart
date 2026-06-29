import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte de statistique (titre + valeur + icône + comparaison).
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.comparison,
    this.comparisonColor,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  /// Texte de comparaison optionnel, ex. « ▲ 12,5 % vs juin 2026 ».
  /// Si [comparisonColor] est fourni, cette couleur est utilisée ; sinon
  /// la couleur est déduite de la flèche (vert pour ▲, rouge pour ▼).
  final String? comparison;

  /// Couleur explicite pour le texte de comparaison. Prioritaire sur la
  /// détection automatique par flèche (utile pour les dépenses : une
  /// hausse = rouge, pas vert).
  final Color? comparisonColor;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: c.withValues(alpha: 0.12),
              foregroundColor: c,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (comparison != null) ...[
                    const SizedBox(height: 4),
                    Text(comparison!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: comparisonColor ??
                                  (comparison!.startsWith('\u25b2')
                                      ? Colors.green.shade700
                                      : comparison!.startsWith('\u25bc')
                                          ? Colors.red.shade700
                                          : null),
                            )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rendu standardisé d'un AsyncValue (chargement / erreur / données).
class AsyncView<T> extends StatelessWidget {
  const AsyncView({required this.value, required this.builder, super.key});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Erreur : $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ),
    );
  }
}

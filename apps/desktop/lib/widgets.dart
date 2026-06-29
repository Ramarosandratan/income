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
  final String? comparison;
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
      loading: () => const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text('Erreur : $e',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// État vide illustré avec icône, titre et message optionnel.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.actionLabel,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: scheme.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
                onPressed: action,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Titre de section réutilisable avec option d'action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.action,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (action != null && actionLabel != null) ...[
          const Spacer(),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(actionLabel!),
            onPressed: action,
          ),
        ],
      ],
    );
  }
}

/// Petit badge de statut coloré.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}

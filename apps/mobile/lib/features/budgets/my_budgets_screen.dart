import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';

/// Détail des enveloppes du membre et de leur consommation.
class MyBudgetsScreen extends ConsumerWidget {
  const MyBudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(mySummaryProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final catById = {for (final c in categories) c.id: c};
    final period = ref.watch(selectedPeriodProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Mes budgets · ${Period.labelFr(period)}',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
            child: summary == null || summary.lines.isEmpty
                ? const Center(child: Text('Aucun budget alloué ce mois-ci.'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final line in summary.lines)
                        _BudgetLineCard(
                          name: line.categoryId == null
                              ? 'Général'
                              : (catById[line.categoryId]?.name ?? 'Catégorie'),
                          icon: CategoryVisuals.icon(
                              catById[line.categoryId]?.icon ?? 'all_inbox'),
                          color: CategoryVisuals.color(
                              catById[line.categoryId]?.color ?? 'FF607D8B'),
                          line: line,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BudgetLineCard extends StatelessWidget {
  const _BudgetLineCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.line,
  });

  final String name;
  final IconData icon;
  final Color color;
  final BudgetLine line;

  @override
  Widget build(BuildContext context) {
    final ratio = line.ratio.clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(name,
                        style: Theme.of(context).textTheme.titleMedium)),
                Text(
                  '${Money.format(line.spent)} / ${Money.format(line.allocated)}',
                  style: TextStyle(
                      color: line.isExceeded
                          ? Theme.of(context).colorScheme.error
                          : null),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: line.allocated <= 0 ? 0 : ratio,
                minHeight: 8,
                color: line.isExceeded
                    ? Theme.of(context).colorScheme.error
                    : (line.isWarning ? Colors.orange : Colors.green),
              ),
            ),
            const SizedBox(height: 4),
            Text('Reste : ${Money.format(line.remaining)}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

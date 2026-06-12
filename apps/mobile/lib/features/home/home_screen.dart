import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final summary = ref.watch(mySummaryProvider);
    final expenses = ref.watch(myMonthExpensesProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final catById = {for (final c in categories) c.id: c};
    final period = ref.watch(selectedPeriodProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bonjour${profile != null ? ', ${profile.fullName.split(' ').first}' : ''}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
          _PeriodSelector(period: period),
          const SizedBox(height: 8),
          if (summary != null) _BudgetCard(summary: summary),
          const SizedBox(height: 20),
          Text('Dépenses récentes',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aucune dépense ce mois-ci.')),
            )
          else
            for (final e in expenses)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: CategoryVisuals.color(
                            catById[e.categoryId]?.color ?? 'FF9E9E9E')
                        .withValues(alpha: 0.15),
                    child: Icon(CategoryVisuals.icon(
                        catById[e.categoryId]?.icon ?? 'category')),
                  ),
                  title: Text(e.note?.isNotEmpty == true
                      ? e.note!
                      : (catById[e.categoryId]?.name ?? 'Dépense')),
                  subtitle: Text(
                      '${catById[e.categoryId]?.name ?? '—'} · ${e.type.labelFr}'),
                  trailing: Text(Money.format(e.amount),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({required this.period});
  final DateTime period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(selectedPeriodProvider.notifier).state =
              Period.previous(period),
        ),
        Text(Period.labelFr(period),
            style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => ref.read(selectedPeriodProvider.notifier).state =
              Period.next(period),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.summary});
  final MemberBudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = summary.ratio.clamp(0.0, 1.0).toDouble();
    final over = summary.remaining < 0;
    final hasBudget = summary.totalAllocated > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Reste à dépenser',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              hasBudget ? Money.format(summary.remaining) : '—',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: over ? scheme.error : scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: hasBudget ? ratio : 0,
                minHeight: 12,
                color: over
                    ? scheme.error
                    : (ratio >= 0.8 ? Colors.orange : scheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dépensé : ${Money.format(summary.totalSpent)}'),
                Text('Budget : ${Money.format(summary.totalAllocated)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

final savingsProvider = FutureProvider<List<SavingsGoal>>(
    (ref) => ref.watch(savingsRepositoryProvider).list());

/// Graphiques (répartition, comparaison) + objectifs d'épargne.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(periodExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final members = ref.watch(membersProvider);
    final savings = ref.watch(savingsProvider);
    final calc = ref.watch(budgetCalculatorProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Rapports', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChartCard(
                title: 'Répartition par catégorie',
                child: AsyncView(
                  value: expenses,
                  builder: (list) {
                    final cats = categories.valueOrNull ?? const <Category>[];
                    final catById = {for (final c in cats) c.id: c};
                    final byCat = calc.spentByCategory(list);
                    if (byCat.isEmpty) {
                      return const Center(child: Text('Pas de dépense.'));
                    }
                    return PieChart(PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 48,
                      sections: [
                        for (final entry in byCat.entries)
                          PieChartSectionData(
                            value: entry.value,
                            title: catById[entry.key]?.name ?? 'Autre',
                            radius: 90,
                            titleStyle: const TextStyle(
                                fontSize: 11, color: Colors.white),
                            color: CategoryVisuals.color(
                                catById[entry.key]?.color ?? 'FF9E9E9E'),
                          ),
                      ],
                    ));
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ChartCard(
                title: 'Dépenses par membre',
                child: AsyncView(
                  value: expenses,
                  builder: (list) {
                    final memberList =
                        members.valueOrNull ?? const <Profile>[];
                    final totals = <String, double>{};
                    for (final e in list) {
                      totals[e.memberId] =
                          (totals[e.memberId] ?? 0) + e.amount;
                    }
                    if (memberList.isEmpty) {
                      return const Center(child: Text('Aucun membre.'));
                    }
                    final maxY = (totals.values.isEmpty
                            ? 0
                            : totals.values.reduce((a, b) => a > b ? a : b)) *
                        1.2;
                    return BarChart(BarChartData(
                      maxY: maxY <= 0 ? 10 : maxY,
                      barGroups: [
                        for (var i = 0; i < memberList.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: totals[memberList[i].id] ?? 0,
                              width: 22,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ]),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: true, reservedSize: 40)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= memberList.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                    memberList[i].fullName.split(' ').first,
                                    style: const TextStyle(fontSize: 11)),
                              );
                            },
                          ),
                        ),
                      ),
                    ));
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text('Objectifs d\'épargne',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nouvel objectif'),
              onPressed: () => _showGoalDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncView(
          value: savings,
          builder: (goals) {
            if (goals.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun objectif défini.'),
              );
            }
            return Column(
              children: [for (final g in goals) _GoalTile(goal: g)],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showGoalDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final target = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvel objectif'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 12),
              TextField(
                controller: target,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Montant cible', suffixText: '€'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final value =
                  double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
              if (name.text.trim().isEmpty || value <= 0) return;
              final profile = await ref.read(currentProfileProvider.future);
              await ref.read(savingsRepositoryProvider).upsert(
                    SavingsGoal(
                      id: '',
                      familyId: profile!.familyId,
                      name: name.text.trim(),
                      targetAmount: value,
                      createdAt: DateTime.now(),
                    ),
                    profile.familyId,
                  );
              ref.invalidate(savingsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(height: 240, child: child),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal});
  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.name, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                    '${Money.format(goal.currentAmount)} / ${Money.format(goal.targetAmount)}'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ajouter une contribution',
                  onPressed: () => _contribute(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 10,
                color: goal.isReached ? Colors.green : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contribute(BuildContext context, WidgetRef ref) async {
    final amount = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contribution — ${goal.name}'),
        content: TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Montant', suffixText: '€'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final value =
                  double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
              if (value <= 0) return;
              await ref.read(savingsRepositoryProvider).contribute(goal.id, value);
              ref.invalidate(savingsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

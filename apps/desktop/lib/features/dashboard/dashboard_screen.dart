import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomes = ref.watch(periodIncomesProvider);
    final expenses = ref.watch(periodExpensesProvider);
    final memberStats = ref.watch(memberExpenseStatsProvider);
    final members = ref.watch(membersProvider);
    final calc = ref.watch(budgetCalculatorProvider);
    final scheme = Theme.of(context).colorScheme;

    final prevIncomes = ref.watch(previousPeriodIncomesProvider);
    final prevExpenses = ref.watch(previousPeriodExpensesProvider);
    final prevPeriod = ref.watch(previousPeriodProvider);

    final totalIncome =
        incomes.valueOrNull?.fold<double>(0, (s, i) => s + i.amount) ?? 0;
    final totalSpent =
        expenses.valueOrNull?.fold<double>(0, (s, e) => s + e.amount) ?? 0;

    final prevTotalIncome =
        prevIncomes.valueOrNull?.fold<double>(0, (s, i) => s + i.amount) ?? 0;
    final prevTotalSpent =
        prevExpenses.valueOrNull?.fold<double>(0, (s, e) => s + e.amount) ?? 0;

    final prevLabel = Period.labelFr(prevPeriod);

    String? comparisonText(double current, double previous) {
      if (previous == 0) return null;
      final pct = ((current - previous) / previous * 100);
      final arrow = pct >= 0 ? '▲' : '▼';
      return '$arrow ${pct.toStringAsFixed(1).replaceAll('-', '')} % vs $prevLabel';
    }

    Color? compColor(bool isExpense, double current, double previous) {
      if (previous == 0) return null;
      final pct = (current - previous) / previous;
      final isGood = isExpense ? pct < 0 : pct >= 0;
      return isGood ? Colors.green.shade700 : Colors.red.shade700;
    }

    final incomeComp = comparisonText(totalIncome, prevTotalIncome);
    final expenseComp = comparisonText(totalSpent, prevTotalSpent);

    final balance = totalIncome - totalSpent;
    final prevBalance = prevTotalIncome - prevTotalSpent;
    final balanceComp = comparisonText(balance, prevBalance);

    final incomeColor = compColor(false, totalIncome, prevTotalIncome);
    final expenseColor = compColor(true, totalSpent, prevTotalSpent);
    final balanceColor = compColor(false, balance, prevBalance);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Tableau de bord',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        // Stats cards
        Row(
          children: [
            Expanded(
                child: StatCard(
                    label: 'Revenus du mois',
                    value: Money.format(totalIncome),
                    icon: Icons.trending_up,
                    color: Colors.teal,
                    comparison: incomeComp,
                    comparisonColor: incomeColor)),
            const SizedBox(width: 16),
            Expanded(
                child: StatCard(
                    label: 'Dépenses du mois',
                    value: Money.format(totalSpent),
                    icon: Icons.trending_down,
                    color: Colors.deepOrange,
                    comparison: expenseComp,
                    comparisonColor: expenseColor)),
            const SizedBox(width: 16),
            Expanded(
                child: StatCard(
                    label: 'Solde',
                    value: Money.format(balance),
                    icon: Icons.account_balance,
                    color: balance >= 0 ? Colors.green : Colors.red,
                    comparison: balanceComp,
                    comparisonColor: balanceColor)),
          ],
        ),
        const SizedBox(height: 28),
        // Charts
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChartCard(
                title: 'Répartition par catégorie',
                child: AsyncView(
                  value: expenses,
                  builder: (list) {
                    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
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
                    final memberList = members.valueOrNull ?? const <Profile>[];
                    final totals = <String, double>{};
                    for (final e in list) {
                      totals[e.memberId] = (totals[e.memberId] ?? 0) + e.amount;
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
                              color: scheme.primary,
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
        // Calendar forecast
        _CalendarForecastSection(),
        const SizedBox(height: 28),
        // Savings goals
        _SavingsSection(),
        const SizedBox(height: 28),
        // Member breakdown
        Row(
          children: [
            Text('Dépenses par membre',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text('Total : ${Money.format(totalSpent)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        AsyncView(
          value: memberStats,
          builder: (list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Aucun membre. Ajoutez-en dans l'onglet Membres."),
              );
            }
            return Column(
              children: [
                for (final s in list)
                  _MemberExpenseTile(
                    memberName: s.memberName,
                    totalSpent: s.totalSpent,
                    percentage: s.percentage,
                    mainCategoryName: s.mainCategoryName,
                    mainCategoryColor: s.mainCategoryColor,
                    scheme: scheme,
                  ),
              ],
            );
          },
        ),
      ],
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

class _CalendarForecastSection extends ConsumerWidget {
  const _CalendarForecastSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrences = ref.watch(calendarOccurrencesProvider);
    final stats = ref.watch(calendarStatsProvider);
    final period = ref.watch(selectedPeriodProvider);
    final scheme = Theme.of(context).colorScheme;
    final incomeIds = ref.watch(calendarIncomeIdsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month, color: scheme.primary, size: 22),
            const SizedBox(width: 8),
            Text('Calendrier prévisionnel',
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Projection des dépenses et revenus récurrents du mois.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        AsyncView(
          value: occurrences,
          builder: (list) => Column(
            children: [
              Row(
                children: [
                  _MiniStatCard(
                    icon: Icons.receipt_long,
                    label: 'Dépenses prévues',
                    value: Money.format(stats.totalDepenses),
                    sub: '${stats.nbOccurrences} occurrences',
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 12),
                  _MiniStatCard(
                    icon: Icons.trending_up,
                    label: 'Revenus prévus',
                    value: Money.format(stats.totalRevenus),
                    sub: '${stats.totalRevenus - stats.totalDepenses >= 0 ? '+' : ''}${Money.format(stats.totalRevenus - stats.totalDepenses)}',
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 12),
                  _MiniStatCard(
                    icon: Icons.check_circle,
                    label: 'Confirmé',
                    value: Money.format(stats.confirme),
                    sub: null,
                    color: scheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CalendarGrid(
                year: period.year,
                month: period.month,
                occurrences: list,
                incomeIds: incomeIds,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                radius: 18,
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: color)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    if (sub != null) ...[
                      const SizedBox(height: 1),
                      Text(sub!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.occurrences,
    required this.incomeIds,
  });

  final int year;
  final int month;
  final List<OccurrenceResolu> occurrences;
  final Set<String> incomeIds;

  static const _jourSemaine = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
  ];

  @override
  Widget build(BuildContext context) {
    final premier = DateTime(year, month, 1);
    final dernier = DateTime(year, month + 1, 0);
    final nbJours = dernier.day;
    final decalage = premier.weekday - 1;

    final depensesParJour = <int, List<OccurrenceResolu>>{};
    final revenusParJour = <int, List<OccurrenceResolu>>{};
    for (final o in occurrences) {
      if (incomeIds.contains(o.idDepense)) {
        (revenusParJour[o.date.day] ??= []).add(o);
      } else {
        (depensesParJour[o.date.day] ??= []).add(o);
      }
    }

    final today = DateTime.now();
    final weeks = (nbJours + decalage + 6) ~/ 7;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                for (final j in _jourSemaine)
                  Expanded(
                    child: Center(
                      child: Text(j,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(weeks, (semaine) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: List.generate(7, (col) {
                    final jour = semaine * 7 + col - decalage + 1;
                    final isToday = year == today.year &&
                        month == today.month &&
                        jour == today.day;
                    return Expanded(
                      child: jour < 1 || jour > nbJours
                          ? const SizedBox(height: 48)
                          : _CalendarDayCell(
                              day: jour,
                              depenses: depensesParJour[jour] ?? [],
                              revenus: revenusParJour[jour] ?? [],
                              isToday: isToday,
                            ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.depenses,
    required this.revenus,
    this.isToday = false,
  });

  final int day;
  final List<OccurrenceResolu> depenses;
  final List<OccurrenceResolu> revenus;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalDepenses = depenses
        .where((o) => o.estInclusDansTotal)
        .fold<double>(0, (s, o) => s + o.montantFinal);
    final totalRevenus = revenus
        .where((o) => o.estInclusDansTotal)
        .fold<double>(0, (s, o) => s + o.montantFinal);

    final hasActivity = depenses.isNotEmpty || revenus.isNotEmpty;

    return Container(
      height: 48,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isToday
            ? scheme.primaryContainer.withValues(alpha: 0.4)
            : hasActivity
                ? scheme.secondaryContainer.withValues(alpha: 0.2)
                : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? scheme.primary : null,
                ),
          ),
          if (hasActivity) ...[
            if (totalDepenses > 0)
              Text(
                '-${Money.format(totalDepenses).replaceAll(' \u20ac', '')}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      color: Colors.red.shade400,
                    ),
              ),
            if (totalRevenus > 0)
              Text(
                '+${Money.format(totalRevenus).replaceAll(' \u20ac', '')}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      color: Colors.green.shade500,
                    ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SavingsSection extends ConsumerWidget {
  const _SavingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savings = ref.watch(savingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Objectifs d'\u00e9pargne",
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
                    labelText: 'Montant cible', suffixText: '\u20ac'),
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
            child: const Text('Cr\u00e9er'),
          ),
        ],
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
        title: Text('Contribution \u2014 ${goal.name}'),
        content: TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Montant', suffixText: '\u20ac'),
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
              await ref
                  .read(savingsRepositoryProvider)
                  .contribute(goal.id, value);
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

class _MemberExpenseTile extends StatelessWidget {
  const _MemberExpenseTile({
    required this.memberName,
    required this.totalSpent,
    required this.percentage,
    this.mainCategoryName,
    this.mainCategoryColor,
    required this.scheme,
  });

  final String memberName;
  final double totalSpent;
  final double percentage;
  final String? mainCategoryName;
  final String? mainCategoryColor;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(memberName,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  Money.format(totalSpent),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (mainCategoryName != null)
              Row(
                children: [
                  Icon(Icons.label_outline,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Principalement : $mainCategoryName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

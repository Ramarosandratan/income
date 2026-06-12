import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

/// Vue d'ensemble du foyer pour le mois sélectionné.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomes = ref.watch(periodIncomesProvider);
    final expenses = ref.watch(periodExpensesProvider);
    final summaries = ref.watch(memberSummariesProvider);
    final members = ref.watch(membersProvider);

    final totalIncome =
        incomes.valueOrNull?.fold<double>(0, (s, i) => s + i.amount) ?? 0;
    final totalSpent =
        expenses.valueOrNull?.fold<double>(0, (s, e) => s + e.amount) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Tableau de bord',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: StatCard(
                    label: 'Revenus du mois',
                    value: Money.format(totalIncome),
                    icon: Icons.trending_up,
                    color: Colors.teal)),
            const SizedBox(width: 16),
            Expanded(
                child: StatCard(
                    label: 'Dépenses du mois',
                    value: Money.format(totalSpent),
                    icon: Icons.trending_down,
                    color: Colors.deepOrange)),
            const SizedBox(width: 16),
            Expanded(
                child: StatCard(
                    label: 'Solde',
                    value: Money.format(totalIncome - totalSpent),
                    icon: Icons.account_balance,
                    color: totalIncome - totalSpent >= 0
                        ? Colors.green
                        : Colors.red)),
          ],
        ),
        const SizedBox(height: 28),
        Text('Budgets par membre',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        AsyncView(
          value: summaries,
          builder: (list) {
            final byId = {
              for (final m in members.valueOrNull ?? const <Profile>[])
                m.id: m
            };
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun membre. Ajoutez-en dans l\'onglet Membres.'),
              );
            }
            return Column(
              children: [
                for (final s in list)
                  _MemberProgressTile(
                    name: byId[s.memberId]?.fullName ?? 'Membre',
                    summary: s,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MemberProgressTile extends StatelessWidget {
  const _MemberProgressTile({required this.name, required this.summary});
  final String name;
  final MemberBudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final ratio = summary.ratio.clamp(0.0, 1.0).toDouble();
    final over = summary.totalSpent > summary.totalAllocated &&
        summary.totalAllocated > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${Money.format(summary.totalSpent)} / ${Money.format(summary.totalAllocated)}',
                  style: TextStyle(
                      color: over ? Theme.of(context).colorScheme.error : null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: summary.totalAllocated <= 0 ? 0 : ratio,
                minHeight: 10,
                color: over
                    ? Theme.of(context).colorScheme.error
                    : (ratio >= 0.8 ? Colors.orange : Colors.green),
              ),
            ),
            const SizedBox(height: 4),
            Text('Reste : ${Money.format(summary.remaining)}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

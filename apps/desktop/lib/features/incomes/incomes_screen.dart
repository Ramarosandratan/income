import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

/// Saisie et suivi des revenus du foyer (par membre ou globaux).
class IncomesScreen extends ConsumerWidget {
  const IncomesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomes = ref.watch(periodIncomesProvider);
    final members = ref.watch(membersProvider);
    final byId = {
      for (final m in members.valueOrNull ?? const <Profile>[]) m.id: m
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Revenus', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un revenu'),
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncView(
              value: incomes,
              builder: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Aucun revenu ce mois-ci.'));
                }
                final total = list.fold<double>(0, (s, i) => s + i.amount);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          for (final i in list)
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.payments),
                                title: Text(i.source),
                                subtitle: Text(i.memberId == null
                                    ? 'Foyer'
                                    : byId[i.memberId]?.fullName ?? 'Membre'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(Money.format(i.amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        await ref
                                            .read(incomeRepositoryProvider)
                                            .delete(i.id);
                                        refreshAll(ref);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('Total : ${Money.format(total)}',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final source = TextEditingController();
    final amount = TextEditingController();
    String? memberId; // null = foyer
    final members = (await ref.read(membersProvider.future))
        .where((m) => m.role == UserRole.member)
        .toList();

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouveau revenu'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: source,
                  decoration: const InputDecoration(labelText: 'Source'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Montant', suffixText: '€'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: memberId,
                  decoration: const InputDecoration(labelText: 'Attribué à'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Foyer')),
                    for (final m in members)
                      DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                  ],
                  onChanged: (v) => setState(() => memberId = v),
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
                    double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                if (source.text.trim().isEmpty || value <= 0) return;
                final profile = await ref.read(currentProfileProvider.future);
                final period = ref.read(selectedPeriodProvider);
                await ref.read(incomeRepositoryProvider).add(
                      Income(
                        id: '',
                        familyId: profile!.familyId,
                        memberId: memberId,
                        source: source.text.trim(),
                        amount: value,
                        period: period,
                        createdAt: DateTime.now(),
                      ),
                      profile.familyId,
                    );
                refreshAll(ref);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}

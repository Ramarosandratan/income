import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

final recurringListProvider = FutureProvider<List<RecurringTemplate>>(
    (ref) => ref.watch(recurringRepositoryProvider).list());

/// Dépenses (et revenus) fixes générés automatiquement chaque mois/semaine.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(recurringListProvider);
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
              Text('Dépenses fixes',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle récurrence'),
                onPressed: () => _showDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Générées automatiquement à l\'échéance par la tâche planifiée.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncView(
              value: templates,
              builder: (list) {
                if (list.isEmpty) {
                  return const Center(
                      child: Text('Aucune dépense fixe enregistrée.'));
                }
                return ListView(
                  children: [
                    for (final t in list)
                      Card(
                        child: SwitchListTile(
                          secondary: CircleAvatar(
                            child: Icon(t.kind == EntryKind.income
                                ? Icons.payments
                                : Icons.autorenew),
                          ),
                          title: Text(t.label),
                          subtitle: Text(
                            '${Money.format(t.amount)} · '
                            '${t.frequency == Frequency.monthly ? 'mensuel' : 'hebdo'} · '
                            '${byId[t.memberId]?.fullName ?? 'Membre'} · '
                            'prochaine : ${Period.labelFr(t.nextRun)}',
                          ),
                          value: t.active,
                          onChanged: (v) async {
                            await ref
                                .read(recurringRepositoryProvider)
                                .setActive(t.id, v);
                            ref.invalidate(recurringListProvider);
                          },
                        ),
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

  Future<void> _showDialog(BuildContext context, WidgetRef ref) async {
    final label = TextEditingController();
    final amount = TextEditingController();
    final members = (await ref.read(membersProvider.future))
        .where((m) => m.role == UserRole.member)
        .toList();
    final cats = await ref.read(categoriesProvider.future);
    String? memberId = members.isEmpty ? null : members.first.id;
    String? categoryId;
    var frequency = Frequency.monthly;
    var kind = EntryKind.expense;

    if (!context.mounted || memberId == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle récurrence'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: label,
                      decoration:
                          const InputDecoration(labelText: 'Libellé (ex. Loyer)')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Montant', suffixText: '€'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EntryKind>(
                    initialValue: kind,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                          value: EntryKind.expense, child: Text('Dépense')),
                      DropdownMenuItem(
                          value: EntryKind.income, child: Text('Revenu')),
                    ],
                    onChanged: (v) => setState(() => kind = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: memberId,
                    decoration: const InputDecoration(labelText: 'Membre'),
                    items: [
                      for (final m in members)
                        DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                    ],
                    onChanged: (v) => setState(() => memberId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Aucune')),
                      for (final c in cats)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Frequency>(
                    initialValue: frequency,
                    decoration: const InputDecoration(labelText: 'Fréquence'),
                    items: const [
                      DropdownMenuItem(
                          value: Frequency.monthly, child: Text('Mensuelle')),
                      DropdownMenuItem(
                          value: Frequency.weekly, child: Text('Hebdomadaire')),
                    ],
                    onChanged: (v) => setState(() => frequency = v!),
                  ),
                ],
              ),
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
                if (label.text.trim().isEmpty || value <= 0) return;
                final profile = await ref.read(currentProfileProvider.future);
                final nextRun =
                    Period.next(ref.read(selectedPeriodProvider));
                await ref.read(recurringRepositoryProvider).upsert(
                      RecurringTemplate(
                        id: '',
                        familyId: profile!.familyId,
                        memberId: memberId!,
                        categoryId: categoryId,
                        label: label.text.trim(),
                        amount: value,
                        kind: kind,
                        frequency: frequency,
                        nextRun: nextRun,
                      ),
                      profile.familyId,
                    );
                ref.invalidate(recurringListProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

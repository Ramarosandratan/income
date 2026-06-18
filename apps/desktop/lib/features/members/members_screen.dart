import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

/// Liste des membres, invitation d'un nouveau membre et consultation de ses
/// dépenses du mois.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                'Membres',
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              );
              final inviteButton = FilledButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Inviter un membre'),
                onPressed: () => _showInvite(context, ref),
              );
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    inviteButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  inviteButton,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncView(
              value: members,
              builder: (list) => ListView(
                children: [
                  for (final m in list)
                    Card(
                      child: ListTile(
                        leading:
                            CircleAvatar(child: Text(_initials(m.fullName))),
                        title: Text(m.fullName),
                        subtitle: Text(m.isMaster ? 'Maître' : 'Membre'),
                        trailing: m.isMaster
                            ? null
                            : TextButton.icon(
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Voir les dépenses'),
                                onPressed: () => _showExpenses(context, ref, m),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  Future<void> _showExpenses(
      BuildContext context, WidgetRef ref, Profile member) async {
    final period = ref.read(selectedPeriodProvider);
    final from = DateTime(period.year, period.month, 1);
    final to = DateTime(period.year, period.month + 1, 1)
        .subtract(const Duration(seconds: 1));
    final expenses = await ref
        .read(expenseRepositoryProvider)
        .list(memberId: member.id, from: from, to: to);
    final cats = await ref.read(categoriesProvider.future);
    final catById = {for (final c in cats) c.id: c};

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.fullName} — ${Period.labelFr(period)}'),
        content: SizedBox(
          width: 460,
          height: 420,
          child: expenses.isEmpty
              ? const Center(child: Text('Aucune dépense ce mois-ci.'))
              : ListView(
                  children: [
                    for (final e in expenses)
                      ListTile(
                        leading: Icon(CategoryVisuals.icon(
                            catById[e.categoryId]?.icon ?? 'category')),
                        title: Text(e.note?.isNotEmpty == true
                            ? e.note!
                            : (catById[e.categoryId]?.name ?? 'Dépense')),
                        subtitle: Text(
                            '${catById[e.categoryId]?.name ?? '—'} · ${e.type.labelFr}'),
                        trailing: Text(Money.format(e.amount)),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _showInvite(BuildContext context, WidgetRef ref) async {
    final email = TextEditingController();
    final name = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inviter un membre'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 12),
              TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              Text(
                'Un compte membre sera créé ; un mot de passe temporaire '
                'sera renvoyé.',
                style: Theme.of(context).textTheme.bodySmall,
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
              if (name.text.trim().isEmpty || email.text.trim().isEmpty) return;
              try {
                await ref.read(profileRepositoryProvider).inviteMember(
                      email: email.text.trim(),
                      fullName: name.text.trim(),
                    );
                refreshAll(ref);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Erreur : $e')));
                }
              }
            },
            child: const Text('Inviter'),
          ),
        ],
      ),
    );
  }
}

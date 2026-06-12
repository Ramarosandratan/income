import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';

/// Liste des alertes budgétaires du membre (temps réel).
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(myAlertsProvider);
    final myId = ref.watch(myIdProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Alertes',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: myId == null
                      ? null
                      : () => ref
                          .read(alertRepositoryProvider)
                          .markAllRead(myId),
                  child: const Text('Tout marquer lu'),
                ),
              ],
            ),
          ),
          Expanded(
            child: alerts.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (list) => list.isEmpty
                  ? const Center(child: Text('Aucune alerte. Tout va bien 👍'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final a in list)
                          Card(
                            color: a.read
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: 0.4),
                            child: ListTile(
                              leading: Icon(
                                a.kind == AlertKind.budgetExceeded
                                    ? Icons.error
                                    : Icons.warning_amber,
                                color: a.kind == AlertKind.budgetExceeded
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.orange,
                              ),
                              title: Text(a.message),
                              subtitle: Text(_formatDate(a.createdAt)),
                              trailing: a.read
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.done),
                                      onPressed: () => ref
                                          .read(alertRepositoryProvider)
                                          .markRead(a.id),
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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

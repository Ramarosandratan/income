import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';

/// Hub d'alertes famille — le maître voit toutes les alertes de tous les
/// membres en temps réel.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  /// Filtre : null = toutes, true = non lues uniquement.
  bool? _unreadOnly;

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(familyAlertsProvider);
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
              Text('Alertes',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              _FilterChip(
                selected: _unreadOnly == true,
                onSelected: () => setState(() {
                  _unreadOnly = _unreadOnly == true ? null : true;
                }),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.done_all),
                label: const Text('Tout marquer lu'),
                onPressed: _allRead,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Alertes de dépassement budgétaire (80 % et 100 %) pour tous les membres.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: alerts.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erreur : $e',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
              data: (list) {
                var filtered = list;
                if (_unreadOnly == true) {
                  filtered = list.where((a) => !a.read).toList();
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          _unreadOnly == true
                              ? 'Aucune alerte non lue !'
                              : 'Aucune alerte. Tout va bien 👍',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  children: [
                    for (final a in filtered)
                      _AlertCard(
                        alert: a,
                        memberName:
                            byId[a.memberId]?.fullName ?? 'Membre inconnu',
                        onMarkRead: () =>
                            ref.read(alertRepositoryProvider).markRead(a.id),
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

  Future<void> _allRead() async {
    final alerts = ref.read(familyAlertsProvider).valueOrNull ?? [];
    final unread = alerts.where((a) => !a.read);
    for (final a in unread) {
      await ref.read(alertRepositoryProvider).markRead(a.id);
    }
  }
}

/// Chip de filtre « Non lues uniquement ».
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.selected, required this.onSelected});
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: const Text('Non lues uniquement'),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Carte d'alerte individuelle.
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.memberName,
    required this.onMarkRead,
  });

  final Alert alert;
  final String memberName;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final isWarning = alert.kind == AlertKind.budgetWarning;
    final isUnread = !alert.read;

    return Card(
      color: isUnread
          ? (isWarning
              ? Colors.orange.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.25))
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isWarning
              ? Colors.orange.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
          foregroundColor: isWarning ? Colors.orange.shade700 : null,
          child: Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
            color: isWarning
                ? Colors.orange.shade700
                : Theme.of(context).colorScheme.error,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(alert.message)),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isWarning
                      ? Colors.orange
                      : Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Nouveau',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.person,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(memberName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 16),
              Icon(Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(_formatDate(alert.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              if (alert.period != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.calendar_month,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(Period.labelFr(alert.period!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        trailing: isUnread
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Marquer comme lu',
                onPressed: onMarkRead,
              )
            : Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.outline,
                size: 20),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

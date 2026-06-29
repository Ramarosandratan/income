import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';

/// Cadre principal : rail de navigation + en-tête (famille, sélecteur de mois).
class DesktopShell extends ConsumerWidget {
  const DesktopShell({required this.child, super.key});
  final Widget child;

  static const _destinations = [
    ('/dashboard', Icons.dashboard, 'Tableau de bord'),
    ('/budgets', Icons.account_balance_wallet, 'Budgets'),
    ('/expenses', Icons.receipt_long, 'Dépenses'),
    ('/incomes', Icons.payments, 'Revenus'),
    ('/recurring', Icons.autorenew, 'Dépenses fixes'),
    ('/calendar', Icons.calendar_month, 'Calendrier'),
    ('/members', Icons.group, 'Membres'),
    ('/alerts', Icons.notifications, 'Alertes'),
    ('/reports', Icons.bar_chart, 'Rapports'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _destinations.indexWhere((d) => location.startsWith(d.$1));
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final unreadCount = ref.watch(unreadFamilyAlertsCountProvider);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 220,
            selectedIndex: index < 0 ? 0 : index,
            onDestinationSelected: (i) => context.go(_destinations[i].$1),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.savings, size: 28),
                    const SizedBox(width: 8),
                    Text('Income',
                        style: Theme.of(context).textTheme.titleLarge),
                  ]),
                  const SizedBox(height: 4),
                  if (profile != null)
                    Text(profile.fullName,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    tooltip: 'Se déconnecter',
                    icon: const Icon(Icons.logout),
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: d.$2 == Icons.notifications
                      ? Badge(
                          isLabelVisible: unreadCount > 0,
                          label: Text('$unreadCount'),
                          child: const Icon(Icons.notifications_outlined),
                        )
                      : Icon(d.$2),
                  selectedIcon: d.$2 == Icons.notifications
                      ? Badge(
                          isLabelVisible: unreadCount > 0,
                          label: Text('$unreadCount'),
                          child: const Icon(Icons.notifications),
                        )
                      : Icon(d.$2),
                  label: Text(d.$3),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                const Divider(height: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre supérieure avec le sélecteur de mois partagé.
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(selectedPeriodProvider.notifier).state =
                Period.previous(period),
          ),
          SizedBox(
            width: 160,
            child: Center(
              child: Text(
                Period.labelFr(period),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(selectedPeriodProvider.notifier).state =
                Period.next(period),
          ),
        ],
      ),
    );
  }
}

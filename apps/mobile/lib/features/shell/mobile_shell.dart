import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data.dart';

/// Cadre principal mobile : barre de navigation inférieure.
class MobileShell extends ConsumerWidget {
  const MobileShell({required this.child, super.key});
  final Widget child;

  static const _tabs = ['/home', '/budgets', '/savings', '/alerts'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    final unread = ref.watch(unreadAlertsCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil'),
          const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Budgets'),
          const NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Épargne'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Alertes',
          ),
        ],
      ),
      floatingActionButton: location.startsWith('/home')
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/add-expense'),
              icon: const Icon(Icons.add),
              label: const Text('Dépense'),
            )
          : null,
    );
  }
}

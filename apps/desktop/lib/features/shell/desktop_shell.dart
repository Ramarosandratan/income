import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';

/// Sections de navigation avec leurs entres.
class _NavSection {
  final String label;
  final List<_NavItem> items;
  const _NavSection({required this.label, required this.items});
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool showBadge;
  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showBadge = false,
  });
}

const _navSections = [
  _NavSection(label: 'Tableau de bord', items: [
    _NavItem(path: '/dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tableau de bord'),
  ]),
  _NavSection(label: 'Transactions', items: [
    _NavItem(path: '/expenses', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Dpenses'),
    _NavItem(path: '/incomes', icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Revenus'),
  ]),
  _NavSection(label: 'Administration', items: [
    _NavItem(path: '/alerts', icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alertes', showBadge: true),
    _NavItem(path: '/members', icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Membres'),
  ]),
];

/// Cadre principal : rail de navigation + en-tte (famille, slecteur de mois).
class DesktopShell extends ConsumerWidget {
  const DesktopShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final unreadCount = ref.watch(unreadFamilyAlertsCountProvider);
    final scheme = Theme.of(context).colorScheme;

    int currentIndex = 0;
    int itemCount = 0;
    for (final section in _navSections) {
      for (final item in section.items) {
        if (location.startsWith(item.path)) {
          currentIndex = itemCount;
        }
        itemCount++;
      }
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 240,
            selectedIndex: currentIndex,
            backgroundColor: scheme.surface,
            onDestinationSelected: (i) {
              int idx = 0;
              for (final section in _navSections) {
                for (final item in section.items) {
                  if (idx == i) {
                    context.go(item.path);
                    return;
                  }
                  idx++;
                }
              }
            },
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.savings,
                            size: 22, color: scheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text('Income',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(profile.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: 'Se dconnecter',
                    child: IconButton(
                      icon: const Icon(Icons.logout),
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.errorContainer.withValues(alpha: 0.3),
                      ),
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                    ),
                  ),
                ],
              ),
            ),
            groupAlignment: -1.0,
            labelType: NavigationRailLabelType.none,
            destinations: _buildDestinations(unreadCount),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                const Divider(height: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<NavigationRailDestination> _buildDestinations(int unreadCount) {
    final destinations = <NavigationRailDestination>[];
    for (final section in _navSections) {
      for (final item in section.items) {
        final icon = item.showBadge
            ? Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: Icon(item.icon),
              )
            : Icon(item.icon);
        final selectedIcon = item.showBadge
            ? Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: Icon(item.activeIcon),
              )
            : Icon(item.activeIcon);

        destinations.add(
          NavigationRailDestination(
            icon: icon,
            selectedIcon: selectedIcon,
            label: Text(item.label, style: const TextStyle(fontSize: 14)),
          ),
        );
      }
    }
    return destinations;
  }
}

/// Barre suprieure avec le slecteur de mois partag.
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final isCurrentMonth =
        period.month == today.month && period.year == today.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mois prcdent',
            onPressed: () =>
                ref.read(selectedPeriodProvider.notifier).state =
                    Period.previous(period),
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(context, ref, period),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isCurrentMonth
                    ? scheme.primaryContainer.withValues(alpha: 0.4)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Text(
                Period.labelFr(period),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCurrentMonth ? scheme.primary : null,
                    ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Mois suivant',
            onPressed: () =>
                ref.read(selectedPeriodProvider.notifier).state =
                    Period.next(period),
          ),
          const SizedBox(width: 8),
          if (!isCurrentMonth)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () =>
                  ref.read(selectedPeriodProvider.notifier).state =
                      Period.current(),
              child: const Text("Aujourd'hui", style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  void _showMonthPicker(
      BuildContext context, WidgetRef ref, DateTime current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir un mois'),
        content: SizedBox(
          width: 320,
          child: _MonthPickerWidget(
            current: current,
            onSelected: (d) {
              ref.read(selectedPeriodProvider.notifier).state =
                  Period.monthOf(d);
              Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }
}

/// Slecteur mois/anne personnalis.
class _MonthPickerWidget extends StatefulWidget {
  const _MonthPickerWidget({
    required this.current,
    required this.onSelected,
  });

  final DateTime current;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_MonthPickerWidget> createState() => _MonthPickerWidgetState();
}

class _MonthPickerWidgetState extends State<_MonthPickerWidget> {
  late int _year;
  static const _months = [
    'Janvier', 'Fvrier', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Aot', 'Septembre', 'Octobre', 'Novembre', 'Dcembre'
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed:
                  _year > 2020 ? () => setState(() => _year--) : null,
            ),
            Text('$_year',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  _year < 2030 ? () => setState(() => _year++) : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < 12; i++) ...[
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  backgroundColor:
                      _year == widget.current.year && i + 1 == widget.current.month
                          ? scheme.primaryContainer
                          : null,
                ),
                onPressed: () =>
                    widget.onSelected(DateTime(_year, i + 1, 1)),
                child: Text(
                  _months[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        _year == widget.current.year && i + 1 == widget.current.month
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

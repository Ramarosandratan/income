import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:income_core/income_core.dart';

import 'features/alerts/alerts_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/expenses/expenses_screen.dart';
import 'features/incomes/incomes_screen.dart';
import 'features/members/members_screen.dart';
import 'features/shell/desktop_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authServiceProvider).onAuthStateChange,
    ),
    redirect: (context, state) {
      final signedIn = ref.read(authServiceProvider).isSignedIn;
      final loggingIn = state.matchedLocation == '/login';
      if (!signedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => DesktopShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/expenses', builder: (_, __) => const ExpensesScreen()),
          GoRoute(path: '/incomes', builder: (_, __) => const IncomesScreen()),
          GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
          GoRoute(path: '/members', builder: (_, __) => const MembersScreen()),
        ],
      ),
    ],
  );
});

/// Adapte un Stream en Listenable pour go_router.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

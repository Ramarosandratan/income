import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:income_core/income_core.dart';

import 'features/alerts/alerts_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/budgets/my_budgets_screen.dart';
import 'features/expense/add_expense_screen.dart';
import 'features/home/home_screen.dart';
import 'features/savings/my_savings_screen.dart';
import 'features/shell/mobile_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authServiceProvider).onAuthStateChange,
    ),
    redirect: (context, state) {
      final signedIn = ref.read(authServiceProvider).isSignedIn;
      final loggingIn = state.matchedLocation == '/login';
      if (!signedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/add-expense',
          builder: (_, __) => const AddExpenseScreen()),
      ShellRoute(
        builder: (_, __, child) => MobileShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/budgets', builder: (_, __) => const MyBudgetsScreen()),
          GoRoute(path: '/savings', builder: (_, __) => const MySavingsScreen()),
          GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
        ],
      ),
    ],
  );
});

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

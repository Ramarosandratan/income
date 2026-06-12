import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/profile.dart';
import 'repositories/alert_repository.dart';
import 'repositories/budget_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/income_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/recurring_repository.dart';
import 'repositories/savings_repository.dart';
import 'services/auth_service.dart';
import 'services/budget_calculator.dart';
import 'supabase/supabase_config.dart';

/// Client Supabase (singleton initialisé au démarrage).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

final authServiceProvider = Provider<AuthService>(
    (ref) => AuthService(ref.watch(supabaseClientProvider)));

// ── Repositories ──────────────────────────────────────────────────────────
final profileRepositoryProvider = Provider(
    (ref) => ProfileRepository(ref.watch(supabaseClientProvider)));
final categoryRepositoryProvider = Provider(
    (ref) => CategoryRepository(ref.watch(supabaseClientProvider)));
final incomeRepositoryProvider = Provider(
    (ref) => IncomeRepository(ref.watch(supabaseClientProvider)));
final budgetRepositoryProvider = Provider(
    (ref) => BudgetRepository(ref.watch(supabaseClientProvider)));
final expenseRepositoryProvider = Provider(
    (ref) => ExpenseRepository(ref.watch(supabaseClientProvider)));
final recurringRepositoryProvider = Provider(
    (ref) => RecurringRepository(ref.watch(supabaseClientProvider)));
final savingsRepositoryProvider = Provider(
    (ref) => SavingsRepository(ref.watch(supabaseClientProvider)));
final alertRepositoryProvider = Provider(
    (ref) => AlertRepository(ref.watch(supabaseClientProvider)));

final budgetCalculatorProvider =
    Provider((ref) => const BudgetCalculator());

// ── Authentification ────────────────────────────────────────────────────────

/// Émet à chaque changement d'état d'auth (connexion / déconnexion).
final authStateProvider = StreamProvider<AuthState>(
    (ref) => ref.watch(authServiceProvider).onAuthStateChange);

/// Profil du membre connecté (rôle, famille). Se recharge à chaque changement
/// d'auth.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).loadCurrentProfile();
});

/// Mois budgétaire sélectionné dans l'UI (partagé par les écrans).
final selectedPeriodProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month, 1));

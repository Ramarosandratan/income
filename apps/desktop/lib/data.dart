import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

/// Providers de données agrégées pour l'app desktop (toute la famille).
/// Les données « par période » suivent [selectedPeriodProvider].

final membersProvider = FutureProvider<List<Profile>>(
    (ref) => ref.watch(profileRepositoryProvider).listMembers());

final categoriesProvider = FutureProvider<List<Category>>(
    (ref) => ref.watch(categoryRepositoryProvider).list());

({DateTime from, DateTime to}) _monthBounds(DateTime period) {
  final from = DateTime(period.year, period.month, 1);
  final to = DateTime(period.year, period.month + 1, 1)
      .subtract(const Duration(seconds: 1));
  return (from: from, to: to);
}

final periodExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final b = _monthBounds(period);
  return ref.watch(expenseRepositoryProvider).list(from: b.from, to: b.to);
});

final periodIncomesProvider = FutureProvider<List<Income>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(incomeRepositoryProvider).listForPeriod(period);
});

/// Synthèse des dépenses par membre pour le mois sélectionné.
final memberExpenseStatsProvider = FutureProvider<
    List<
        ({
          String memberId,
          String memberName,
          double totalSpent,
          double percentage,
          String? mainCategoryName,
          String? mainCategoryColor
        })>>(
  (ref) async {
    final members = await ref.watch(membersProvider.future);
    final expenses = await ref.watch(periodExpensesProvider.future);
    final catById = {
      for (final c in await ref.watch(categoriesProvider.future)) c.id: c
    };

    final totalFamily = expenses.fold<double>(0, (s, e) => s + e.amount);

    if (totalFamily == 0) {
      return members
          .map((m) => (
                memberId: m.id,
                memberName: m.fullName,
                totalSpent: 0.0,
                percentage: 0.0,
                mainCategoryName: null,
                mainCategoryColor: null,
              ))
          .toList();
    }

    return members.map((m) {
      final memberExpenses = expenses.where((e) => e.memberId == m.id).toList();
      final total = memberExpenses.fold<double>(0, (s, e) => s + e.amount);

      final byCat = <String?, double>{};
      for (final e in memberExpenses) {
        byCat[e.categoryId] = (byCat[e.categoryId] ?? 0) + e.amount;
      }
      String? mainCatId;
      double maxCat = 0;
      for (final entry in byCat.entries) {
        if (entry.value > maxCat) {
          maxCat = entry.value;
          mainCatId = entry.key;
        }
      }

      return (
        memberId: m.id,
        memberName: m.fullName,
        totalSpent: total,
        percentage: (total / totalFamily) * 100,
        mainCategoryName: mainCatId != null ? catById[mainCatId]?.name : null,
        mainCategoryColor: mainCatId != null ? catById[mainCatId]?.color : null,
      );
    }).toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
  },
);

final savingsProvider = FutureProvider<List<SavingsGoal>>(
    (ref) => ref.watch(savingsRepositoryProvider).list());

/// Alertes de toute la famille, en temps réel (pour le maître).
final familyAlertsProvider = StreamProvider<List<Alert>>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  if (profile == null) return Stream.value(const <Alert>[]);
  return ref.watch(alertRepositoryProvider).watchForFamily();
});

/// Nombre d'alertes non lues (pour le badge de navigation).
final unreadFamilyAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(familyAlertsProvider).valueOrNull ?? const [];
  return alerts.where((a) => !a.read).length;
});

/// Mois précédent dérivé de la période sélectionnée.
final previousPeriodProvider = Provider<DateTime>(
    (ref) => Period.previous(ref.watch(selectedPeriodProvider)));

final previousPeriodExpensesProvider =
    FutureProvider<List<Expense>>((ref) async {
  final period = ref.watch(previousPeriodProvider);
  final b = _monthBounds(period);
  return ref.watch(expenseRepositoryProvider).list(from: b.from, to: b.to);
});

final previousPeriodIncomesProvider = FutureProvider<List<Income>>((ref) {
  final period = ref.watch(previousPeriodProvider);
  return ref.watch(incomeRepositoryProvider).listForPeriod(period);
});

/// Invalide tous les providers dépendant des données (après une mutation).
void refreshAll(WidgetRef ref) {
  ref.invalidate(previousPeriodExpensesProvider);
  ref.invalidate(previousPeriodIncomesProvider);
  ref.invalidate(periodExpensesProvider);
  ref.invalidate(periodIncomesProvider);
  ref.invalidate(memberExpenseStatsProvider);
  ref.invalidate(membersProvider);
  ref.invalidate(familyAlertsProvider);
  ref.invalidate(calendarOccurrencesProvider);
}

// Providers du calendrier prévisionnel

Depense _templateToDepense(RecurringTemplate t) {
  final type = switch (t.frequency) {
    Frequency.daily => TypeRecurrence.journalier,
    Frequency.weekly => TypeRecurrence.hebdomadaire,
    Frequency.monthly || Frequency.yearly => TypeRecurrence.mensuel,
  };
  List<int>? params;
  if (t.daysOfWeek != null && t.daysOfWeek!.isNotEmpty) {
    params = t.daysOfWeek!;
  } else if (t.frequencyDay != null) {
    params = [t.frequencyDay!];
  } else if (t.frequency == Frequency.monthly) {
    params = [1];
  } else if (t.frequency == Frequency.weekly) {
    params = [DateTime.monday];
  }
  final intervalle = t.frequency == Frequency.yearly ? 12 : 1;
  final dateDebut = DateTime(t.nextRun.year - 1, 1, 1);
  return Depense(
    id: 'expense:',
    titre: t.label,
    natureMontant: NatureMontant.fixe,
    montantParDefaut: t.amount,
    dateDebut: dateDebut,
    frequence:
        Frequence(type: type, intervalle: intervalle, parametres: params),
    categoryId: t.categoryId,
  );
}

Depense _templateToIncome(RecurringTemplate t) {
  final type = switch (t.frequency) {
    Frequency.daily => TypeRecurrence.journalier,
    Frequency.weekly => TypeRecurrence.hebdomadaire,
    Frequency.monthly || Frequency.yearly => TypeRecurrence.mensuel,
  };
  List<int>? params;
  if (t.daysOfWeek != null && t.daysOfWeek!.isNotEmpty) {
    params = t.daysOfWeek!;
  } else if (t.frequencyDay != null) {
    params = [t.frequencyDay!];
  } else if (t.frequency == Frequency.monthly) {
    params = [1];
  } else if (t.frequency == Frequency.weekly) {
    params = [DateTime.monday];
  }
  final intervalle = t.frequency == Frequency.yearly ? 12 : 1;
  final dateDebut = DateTime(t.nextRun.year - 1, 1, 1);
  return Depense(
    id: 'income:${t.id}',
    titre: t.label,
    natureMontant: NatureMontant.fixe,
    montantParDefaut: t.amount,
    dateDebut: dateDebut,
    frequence:
        Frequence(type: type, intervalle: intervalle, parametres: params),
    categoryId: t.categoryId,
  );
}

final _calendarDepensesProvider = FutureProvider<List<Depense>>((ref) async {
  final templates = await ref.watch(recurringRepositoryProvider).list();
  return templates
      .where((t) => t.active && t.kind == EntryKind.expense)
      .map(_templateToDepense)
      .toList();
});

final _calendarIncomeProvider = FutureProvider<List<Depense>>((ref) async {
  final templates = await ref.watch(recurringRepositoryProvider).list();
  return templates
      .where((t) => t.active && t.kind == EntryKind.income)
      .map(_templateToIncome)
      .toList();
});

final calendarOccurrencesProvider =
    FutureProvider<List<OccurrenceResolu>>((ref) async {
  final depenses = await ref.watch(_calendarDepensesProvider.future);
  final incomes = await ref.watch(_calendarIncomeProvider.future);
  final period = ref.watch(selectedPeriodProvider);
  const engine = CalendarEngine();
  return engine.genererMois(
    depenses: [...depenses, ...incomes],
    overrides: const [],
    anneeCible: period.year,
    moisCible: period.month,
  );
});

final calendarStatsProvider = Provider<
    ({
      double totalDepenses,
      double confirme,
      double totalRevenus,
      int nbOccurrences
    })>(
  (ref) {
    final occurrences =
        ref.watch(calendarOccurrencesProvider).valueOrNull ?? [];
    final incomeIds = ref
            .watch(_calendarIncomeProvider)
            .valueOrNull
            ?.map((d) => d.id)
            .toSet() ??
        {};
    double totalDepenses = 0;
    double totalRevenus = 0;
    double confirme = 0;
    for (final o in occurrences) {
      if (!o.estInclusDansTotal) continue;
      if (incomeIds.contains(o.idDepense)) {
        totalRevenus += o.montantFinal;
      } else {
        totalDepenses += o.montantFinal;
      }
      if (o.statutUI == StatutUI.confirme) {
        confirme += o.montantFinal;
      }
    }
    return (
      totalDepenses: totalDepenses,
      confirme: confirme,
      totalRevenus: totalRevenus,
      nbOccurrences: occurrences.length,
    );
  },
);

final calendarCategoryTotalsProvider =
    Provider<List<({String? categoryId, double montant})>>(
  (ref) {
    final occurrences =
        ref.watch(calendarOccurrencesProvider).valueOrNull ?? [];
    final incomeIds = ref
            .watch(_calendarIncomeProvider)
            .valueOrNull
            ?.map((d) => d.id)
            .toSet() ??
        {};
    final map = <String?, double>{};
    for (final o in occurrences) {
      if (!o.estInclusDansTotal || incomeIds.contains(o.idDepense)) continue;
      map[o.categoryId] = (map[o.categoryId] ?? 0) + o.montantFinal;
    }
    return map.entries
        .map((e) => (categoryId: e.key, montant: e.value))
        .toList()
      ..sort((a, b) => b.montant.compareTo(a.montant));
  },
);

final calendarIncomeIdsProvider = Provider<Set<String>>((ref) {
  return ref
          .watch(_calendarIncomeProvider)
          .valueOrNull
          ?.map((d) => d.id)
          .toSet() ??
      {};
});

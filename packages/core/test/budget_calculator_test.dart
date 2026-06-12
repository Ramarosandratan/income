// Test de logique pure : imports directs des fichiers sans dépendance Flutter,
// pour rester exécutable via `dart test` (le moteur Flutter n'est pas requis).
import 'package:income_core/src/models/budget.dart';
import 'package:income_core/src/models/expense.dart';
import 'package:income_core/src/services/budget_calculator.dart';
import 'package:test/test.dart';

void main() {
  const calc = BudgetCalculator();
  final now = DateTime(2026, 6, 1);

  Budget budget({String? categoryId, required double amount}) => Budget(
        id: 'b-${categoryId ?? 'global'}',
        familyId: 'fam',
        memberId: 'm1',
        categoryId: categoryId,
        period: now,
        amount: amount,
      );

  Expense expense({String? categoryId, required double amount}) => Expense(
        id: 'e-$categoryId-$amount',
        familyId: 'fam',
        memberId: 'm1',
        categoryId: categoryId,
        amount: amount,
        spentAt: now,
        createdAt: now,
      );

  group('BudgetCalculator.summarize', () {
    test('calcule le reste à dépenser global', () {
      final s = calc.summarize(
        memberId: 'm1',
        budgets: [budget(amount: 500)],
        expenses: [expense(amount: 120), expense(amount: 80)],
      );
      expect(s.totalAllocated, 500);
      expect(s.totalSpent, 200);
      expect(s.remaining, 300);
      expect(s.ratio, closeTo(0.4, 1e-9));
    });

    test('rapproche les dépenses par catégorie budgétée', () {
      final s = calc.summarize(
        memberId: 'm1',
        budgets: [budget(categoryId: 'food', amount: 300)],
        expenses: [
          expense(categoryId: 'food', amount: 250),
          expense(categoryId: 'fun', amount: 50), // hors enveloppe catégorisée
        ],
      );
      final food = s.lines.firstWhere((l) => l.categoryId == 'food');
      expect(food.spent, 250);
      expect(food.remaining, 50);
      // La dépense "fun" tombe dans la ligne globale (allocated 0).
      // Sans enveloppe globale, ce n'est pas un "dépassement" (isExceeded
      // exige allocated > 0), mais le reste est négatif.
      final global = s.lines.firstWhere((l) => l.categoryId == null);
      expect(global.spent, 50);
      expect(global.isExceeded, isFalse);
      expect(global.remaining, -50);
    });

    test('détecte avertissement (>=80%) et dépassement', () {
      final s = calc.summarize(
        memberId: 'm1',
        budgets: [budget(categoryId: 'food', amount: 100)],
        expenses: [expense(categoryId: 'food', amount: 85)],
      );
      final food = s.lines.firstWhere((l) => l.categoryId == 'food');
      expect(food.isWarning, isTrue);
      expect(food.isExceeded, isFalse);
    });
  });

  test('spentByCategory regroupe par catégorie', () {
    final map = calc.spentByCategory([
      expense(categoryId: 'a', amount: 10),
      expense(categoryId: 'a', amount: 5),
      expense(categoryId: 'b', amount: 7),
    ]);
    expect(map['a'], 15);
    expect(map['b'], 7);
  });
}

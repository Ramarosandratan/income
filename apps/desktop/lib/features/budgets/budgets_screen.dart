import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

/// Allocation des enveloppes budgétaires par membre et par catégorie.
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  String? _memberId;

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    final period = ref.watch(selectedPeriodProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Budgets — ${Period.labelFr(period)}',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_all),
                label: const Text('Copier vers le mois suivant'),
                onPressed: () async {
                  await ref
                      .read(budgetRepositoryProvider)
                      .copyToNextMonth(period);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Budgets recopiés.')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AsyncView(
            value: members,
            builder: (list) {
              final selectable =
                  list.where((m) => m.role == UserRole.member).toList();
              _memberId ??= selectable.isEmpty ? null : selectable.first.id;
              return SizedBox(
                width: 320,
                child: DropdownButtonFormField<String>(
                  initialValue: _memberId,
                  decoration: const InputDecoration(labelText: 'Membre'),
                  items: [
                    for (final m in selectable)
                      DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                  ],
                  onChanged: (v) => setState(() => _memberId = v),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _memberId == null
                ? const Center(child: Text('Sélectionnez un membre.'))
                : _CategoryBudgetEditor(memberId: _memberId!),
          ),
        ],
      ),
    );
  }
}

/// Éditeur des montants par catégorie pour un membre + une enveloppe globale.
class _CategoryBudgetEditor extends ConsumerWidget {
  const _CategoryBudgetEditor({required this.memberId});
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final budgets = ref.watch(periodBudgetsProvider);

    return AsyncView(
      value: categories,
      builder: (cats) {
        final expenseCats =
            cats.where((c) => c.kind == EntryKind.expense).toList();
        final memberBudgets = (budgets.valueOrNull ?? const <Budget>[])
            .where((b) => b.memberId == memberId)
            .toList();
        double amountFor(String? categoryId) => memberBudgets
            .where((b) => b.categoryId == categoryId)
            .fold<double>(0, (_, b) => b.amount);

        return ListView(
          children: [
            _BudgetRow(
              label: 'Enveloppe globale (hors catégories)',
              icon: Icons.all_inbox,
              initial: amountFor(null),
              onSave: (v) => _save(ref, categoryId: null, amount: v),
            ),
            const Divider(),
            for (final c in expenseCats)
              _BudgetRow(
                label: c.name,
                icon: CategoryVisuals.icon(c.icon),
                color: CategoryVisuals.color(c.color),
                initial: amountFor(c.id),
                onSave: (v) => _save(ref, categoryId: c.id, amount: v),
              ),
          ],
        );
      },
    );
  }

  Future<void> _save(WidgetRef ref,
      {required String? categoryId, required double amount}) async {
    final profile = await ref.read(currentProfileProvider.future);
    final period = ref.read(selectedPeriodProvider);
    await ref.read(budgetRepositoryProvider).upsert(
          Budget(
            id: '',
            familyId: profile!.familyId,
            memberId: memberId,
            categoryId: categoryId,
            period: period,
            amount: amount,
          ),
          profile.familyId,
        );
    refreshAll(ref);
  }
}

class _BudgetRow extends StatefulWidget {
  const _BudgetRow({
    required this.label,
    required this.icon,
    required this.initial,
    required this.onSave,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final double initial;
  final Future<void> Function(double) onSave;

  @override
  State<_BudgetRow> createState() => _BudgetRowState();
}

class _BudgetRowState extends State<_BudgetRow> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial == 0 ? '' : '${widget.initial}');
  bool _saving = false;

  @override
  void didUpdateWidget(_BudgetRow old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && !_saving) {
      _ctrl.text = widget.initial == 0 ? '' : '${widget.initial}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (widget.color ?? Colors.grey).withValues(alpha: 0.15),
        foregroundColor: widget.color,
        child: Icon(widget.icon),
      ),
      title: Text(widget.label),
      trailing: SizedBox(
        width: 200,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(suffixText: '€', isDense: true),
                onSubmitted: (_) => _save(),
              ),
            ),
            IconButton(
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final value = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0;
    setState(() => _saving = true);
    await widget.onSave(value);
    if (mounted) setState(() => _saving = false);
  }
}

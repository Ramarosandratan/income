import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';

/// Saisie rapide d'une dépense par le membre.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _categoryId;
  ExpenseType _type = ExpenseType.daily;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      final id = ref.read(myIdProvider)!;
      await ref.read(expenseRepositoryProvider).add(
            Expense(
              id: '',
              familyId: profile!.familyId,
              memberId: id,
              categoryId: _categoryId,
              amount: value,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              spentAt: _date,
              type: _type,
              createdAt: DateTime.now(),
            ),
            profile.familyId,
            id,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesProvider).valueOrNull?.where((c) => c.kind == EntryKind.expense).toList() ??
            const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle dépense')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              labelText: 'Montant',
              suffixText: '€',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text('Catégorie', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categories)
                ChoiceChip(
                  avatar: Icon(CategoryVisuals.icon(c.icon), size: 18),
                  label: Text(c.name),
                  selected: _categoryId == c.id,
                  onSelected: (_) => setState(() => _categoryId = c.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
                labelText: 'Note (facultatif)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          SegmentedButton<ExpenseType>(
            segments: const [
              ButtonSegment(value: ExpenseType.daily, label: Text('Journalière')),
              ButtonSegment(value: ExpenseType.monthly, label: Text('Mensuelle')),
              ButtonSegment(value: ExpenseType.fixed, label: Text('Fixe')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 20),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            leading: const Icon(Icons.calendar_today),
            title: Text(
                '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

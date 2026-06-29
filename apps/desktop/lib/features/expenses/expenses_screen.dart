import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

/// Navigateur de dépenses — le maître consulte, filtre et gère toutes les
/// dépenses de la famille.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _filterMemberId;
  String? _filterCategoryId;
  final Set<ExpenseType> _filterTypes = {};
  String _searchQuery = '';
  bool _sortAsc = false; // tri par date : plus récent d'abord

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(periodExpensesProvider);
    final members = ref.watch(membersProvider);
    final categories = ref.watch(categoriesProvider);
    final period = ref.watch(selectedPeriodProvider);

    final byId = {
      for (final m in members.valueOrNull ?? const <Profile>[]) m.id: m
    };
    final catById = {
      for (final c in categories.valueOrNull ?? const <Category>[]) c.id: c
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Dépenses — ${Period.labelFr(period)}',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nouvelle dépense'),
                onPressed: () => _addExpense(context),
              ),
              const SizedBox(width: 8),
              // Bouton rafraîchir
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Rafraîchir',
                onPressed: () => refreshAll(ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Filtres ─────────────────────────────────────────────────
          AsyncView(
            value: members,
            builder: (memberList) {
              final memberOptions =
                  memberList.where((m) => m.role == UserRole.member).toList();
              final catList = categories.valueOrNull ?? const <Category>[];
              final expenseCats =
                  catList.where((c) => c.kind == EntryKind.expense).toList();

              return Column(
                children: [
                  // Ligne 1 : membre + catégorie
                  Row(
                    children: [
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _filterMemberId,
                          decoration: const InputDecoration(
                            labelText: 'Membre',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Tous les membres')),
                            for (final m in memberOptions)
                              DropdownMenuItem(
                                  value: m.id, child: Text(m.fullName)),
                          ],
                          onChanged: (v) =>
                              setState(() => _filterMemberId = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _filterCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Toutes les catégories')),
                            for (final c in expenseCats)
                              DropdownMenuItem(
                                  value: c.id, child: Text(c.name)),
                          ],
                          onChanged: (v) =>
                              setState(() => _filterCategoryId = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Recherche textuelle
                      SizedBox(
                        width: 240,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Rechercher',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onChanged: (v) =>
                              setState(() => _searchQuery = v.toLowerCase()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Ligne 2 : types + tri
                  Row(
                    children: [
                      ...ExpenseType.values.map((t) {
                        final selected = _filterTypes.contains(t);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(t.labelFr),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _filterTypes.add(t);
                                } else {
                                  _filterTypes.remove(t);
                                }
                              });
                            },
                          ),
                        );
                      }),
                      const Spacer(),
                      Text('Trier : ', style: Theme.of(context).textTheme.bodySmall),
                      ChoiceChip(
                        label: const Text('Date'),
                        selected: true,
                        onSelected: (_) => setState(() => _sortAsc = !_sortAsc),
                        avatar: Icon(
                          _sortAsc
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // ── Liste des dépenses ──────────────────────────────────────
          Expanded(
            child: AsyncView(
              value: expenses,
              builder: (list) {
                var filtered = list.toList();

                // Filtres
                if (_filterMemberId != null) {
                  filtered =
                      filtered.where((e) => e.memberId == _filterMemberId).toList();
                }
                if (_filterCategoryId != null) {
                  filtered = filtered
                      .where((e) => e.categoryId == _filterCategoryId)
                      .toList();
                }
                if (_filterTypes.isNotEmpty) {
                  filtered =
                      filtered.where((e) => _filterTypes.contains(e.type)).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((e) {
                    final note = (e.note ?? '').toLowerCase();
                    final cat = catById[e.categoryId]?.name.toLowerCase() ?? '';
                    final member =
                        byId[e.memberId]?.fullName.toLowerCase() ?? '';
                    return note.contains(_searchQuery) ||
                        cat.contains(_searchQuery) ||
                        member.contains(_searchQuery);
                  }).toList();
                }

                // Tri
                filtered.sort((a, b) => _sortAsc
                    ? a.spentAt.compareTo(b.spentAt)
                    : b.spentAt.compareTo(a.spentAt));

                final total = filtered.fold<double>(0, (s, e) => s + e.amount);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          _hasActiveFilter
                              ? 'Aucune dépense ne correspond aux filtres.'
                              : 'Aucune dépense ce mois-ci.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // En-tête du tableau
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          _headerCell('Date', flex: 2),
                          _headerCell('Membre', flex: 2),
                          _headerCell('Catégorie', flex: 2),
                          _headerCell('Note', flex: 2),
                          _headerCell('Montant', flex: 2, align: TextAlign.right),
                          _headerCell('Type', flex: 1),
                          _headerCell('Fréquence', flex: 1),
                          const SizedBox(width: 80), // actions
                        ],
                      ),
                    ),
                    // Lignes
                    Expanded(
                      child: ListView(
                        children: [
                          for (final e in filtered)
                            _ExpenseRow(
                              expense: e,
                              memberName:
                                  byId[e.memberId]?.fullName ?? 'Inconnu',
                              categoryName: catById[e.categoryId]?.name,
                              categoryIcon: catById[e.categoryId]?.icon,
                              categoryColor: catById[e.categoryId]?.color,
                              onEdit: () => _editExpense(context, e),
                              onDelete: () => _deleteExpense(context, e),
                            ),
                        ],
                      ),
                    ),
                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Total : ',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            Money.format(total),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_hasActiveFilter)
                            Text(
                              ' (${filtered.length} dépenses)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilter =>
      _filterMemberId != null ||
      _filterCategoryId != null ||
      _filterTypes.isNotEmpty ||
      _searchQuery.isNotEmpty;

  Widget _headerCell(String label,
      {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
          textAlign: align),
    );
  }

  // ── Ajout ────────────────────────────────────────────────────────────
  Future<void> _addExpense(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final allMembers = await ref.read(membersProvider.future);
    final categories = await ref.read(categoriesProvider.future);
    // Inclut tous les membres de la famille (master + members) pour
    // permettre au parent de saisir ses propres dépenses.
    final memberOptions = allMembers.toList();
    final expenseCats =
        categories.where((c) => c.kind == EntryKind.expense).toList();

    String? memberId = memberOptions.isNotEmpty ? memberOptions.first.id : null;
    String? categoryId;
    ExpenseType type = ExpenseType.daily;
    Frequency? frequency;
    int? frequencyDay;
    DateTime date = DateTime.now();

    if (!context.mounted) return;
    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle dépense'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Membre
                DropdownButtonFormField<String?>(
                  initialValue: memberId,
                  decoration: const InputDecoration(labelText: 'Membre', isDense: true),
                  items: [
                    for (final m in memberOptions)
                      DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                  ],
                  onChanged: (v) => setState(() => memberId = v),
                ),
                const SizedBox(height: 12),
                // Montant
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: const InputDecoration(
                      labelText: 'Montant', suffixText: '€', isDense: true),
                ),
                const SizedBox(height: 12),
                // Catégorie
                DropdownButtonFormField<String?>(
                  initialValue: categoryId,
                  decoration:
                      const InputDecoration(labelText: 'Catégorie', isDense: true),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Aucune')),
                    for (final c in expenseCats)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => categoryId = v),
                ),
                const SizedBox(height: 12),
                // Note
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Note (facultatif)', isDense: true),
                ),
                const SizedBox(height: 12),
                // Type (journalière / mensuelle / fixe)
                SegmentedButton<ExpenseType>(
                  segments: const [
                    ButtonSegment(
                        value: ExpenseType.daily, label: Text('Journalière')),
                    ButtonSegment(
                        value: ExpenseType.monthly, label: Text('Mensuelle')),
                    ButtonSegment(
                        value: ExpenseType.fixed, label: Text('Fixe')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setState(() => type = s.first),
                ),
                const SizedBox(height: 12),
                // Fréquence
                DropdownButtonFormField<Frequency?>(
                  initialValue: frequency,
                  decoration:
                      const InputDecoration(labelText: 'Fréquence', isDense: true),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Ponctuelle')),
                    for (final f in Frequency.values)
                      DropdownMenuItem(value: f, child: Text(f.labelFr)),
                  ],
                  onChanged: (v) {
                    setState(() {
                      frequency = v;
                      frequencyDay = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Sélecteur de jour selon la fréquence
                if (frequency == Frequency.weekly)
                  DropdownButtonFormField<int>(
                    initialValue: frequencyDay ?? 1,
                    decoration: const InputDecoration(
                        labelText: 'Jour de la semaine', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Lundi')),
                      DropdownMenuItem(value: 2, child: Text('Mardi')),
                      DropdownMenuItem(value: 3, child: Text('Mercredi')),
                      DropdownMenuItem(value: 4, child: Text('Jeudi')),
                      DropdownMenuItem(value: 5, child: Text('Vendredi')),
                      DropdownMenuItem(value: 6, child: Text('Samedi')),
                      DropdownMenuItem(value: 7, child: Text('Dimanche')),
                    ],
                    onChanged: (v) =>
                        setState(() => frequencyDay = v!),
                  ),
                if (frequency == Frequency.monthly)
                  DropdownButtonFormField<int>(
                    initialValue: frequencyDay ?? 1,
                    decoration: const InputDecoration(
                        labelText: 'Jour du mois', isDense: true),
                    items: [
                      for (int d = 1; d <= 31; d++)
                        DropdownMenuItem(value: d, child: Text('$d')),
                    ],
                    onChanged: (v) =>
                        setState(() => frequencyDay = v!),
                  ),
                const SizedBox(height: 12),
                // Date
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  leading: const Icon(Icons.calendar_today, size: 20),
                  title: Text(
                    '${date.day.toString().padLeft(2, '0')}'
                    '/${date.month.toString().padLeft(2, '0')}'
                    '/${date.year}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton.icon(
              icon: const Icon(Icons.check, size: 18),
              onPressed: () async {
                final value =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                if (value <= 0 || memberId == null) return;

                final profile =
                    await ref.read(currentProfileProvider.future);
                await ref.read(expenseRepositoryProvider).add(
                      Expense(
                        id: '',
                        familyId: profile!.familyId,
                        memberId: memberId!,
                        categoryId: categoryId,
                        amount: value,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                        spentAt: date,
                        type: type,
                        frequency: frequency,
                        frequencyDay: frequencyDay,
                        createdAt: DateTime.now(),
                      ),
                      profile.familyId,
                      memberId!,
                    );
                refreshAll(ref);
                if (context.mounted) Navigator.pop(context, true);
              },
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Édition ───────────────────────────────────────────────────────────
  Future<void> _editExpense(BuildContext context, Expense expense) async {
    final amountCtrl =
        TextEditingController(text: expense.amount.toStringAsFixed(2));
    final noteCtrl = TextEditingController(text: expense.note ?? '');
    final categories = await ref.read(categoriesProvider.future);
    final expenseCats =
        categories.where((c) => c.kind == EntryKind.expense).toList();
    String? categoryId = expense.categoryId;
    ExpenseType type = expense.type;
    Frequency? frequency = expense.frequency;
    int? frequencyDay = expense.frequencyDay;

    if (!context.mounted) return;
    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier la dépense'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Montant', suffixText: '€'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: categoryId,
                  decoration:
                      const InputDecoration(labelText: 'Catégorie'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Aucune')),
                    for (final c in expenseCats)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => categoryId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExpenseType>(
                  initialValue: type,
                  decoration:
                      const InputDecoration(labelText: 'Type'),
                  items: [
                    for (final t in ExpenseType.values)
                      DropdownMenuItem(value: t, child: Text(t.labelFr)),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Frequency?>(
                  initialValue: frequency,
                  decoration:
                      const InputDecoration(labelText: 'Fréquence'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Ponctuelle')),
                    for (final f in Frequency.values)
                      DropdownMenuItem(value: f, child: Text(f.labelFr)),
                  ],
                  onChanged: (v) {
                    setState(() {
                      frequency = v;
                      frequencyDay = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Sélecteur de jour selon la fréquence
                if (frequency == Frequency.weekly)
                  DropdownButtonFormField<int>(
                    initialValue: frequencyDay ?? 1,
                    decoration: const InputDecoration(
                        labelText: 'Jour de la semaine', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Lundi')),
                      DropdownMenuItem(value: 2, child: Text('Mardi')),
                      DropdownMenuItem(value: 3, child: Text('Mercredi')),
                      DropdownMenuItem(value: 4, child: Text('Jeudi')),
                      DropdownMenuItem(value: 5, child: Text('Vendredi')),
                      DropdownMenuItem(value: 6, child: Text('Samedi')),
                      DropdownMenuItem(value: 7, child: Text('Dimanche')),
                    ],
                    onChanged: (v) =>
                        setState(() => frequencyDay = v!),
                  ),
                if (frequency == Frequency.monthly)
                  DropdownButtonFormField<int>(
                    initialValue: frequencyDay ?? 1,
                    decoration: const InputDecoration(
                        labelText: 'Jour du mois', isDense: true),
                    items: [
                      for (int d = 1; d <= 31; d++)
                        DropdownMenuItem(value: d, child: Text('$d')),
                    ],
                    onChanged: (v) =>
                        setState(() => frequencyDay = v!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                if (amount <= 0) return;
                // Construire une nouvelle dépense directement (pas copyWith)
                // pour pouvoir effacer les champs nullables (note, frequency,
                // frequencyDay).
                await ref.read(expenseRepositoryProvider).update(Expense(
                      id: expense.id,
                      familyId: expense.familyId,
                      memberId: expense.memberId,
                      categoryId: categoryId,
                      amount: amount,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                      spentAt: expense.spentAt,
                      type: type,
                      frequency: frequency,
                      frequencyDay: frequencyDay,
                      recurringTemplateId: expense.recurringTemplateId,
                      createdAt: expense.createdAt,
                    ));
                refreshAll(ref);
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Suppression ───────────────────────────────────────────────────────
  Future<void> _deleteExpense(
      BuildContext context, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense'),
        content: Text(
            'Voulez-vous vraiment supprimer cette dépense de ${Money.format(expense.amount)} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(expenseRepositoryProvider).delete(expense.id);
      refreshAll(ref);
    }
  }
}

/// Ligne d'une dépense dans la liste.
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.memberName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final String memberName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: CategoryVisuals.color(categoryColor ?? 'FF9E9E9E')
              .withValues(alpha: 0.15),
          child: Icon(
            CategoryVisuals.icon(categoryIcon ?? 'category'),
            size: 18,
            color: CategoryVisuals.color(categoryColor ?? 'FF9E9E9E'),
          ),
        ),
        title: Row(
          children: [
            _cell(context, _formatDate(expense.spentAt), flex: 2),
            _cell(context, memberName, flex: 2),
            _cell(context, categoryName ?? '—', flex: 2),
            _cell(context, expense.note ?? '', flex: 2),
            _cell(context, Money.format(expense.amount),
                flex: 2, align: TextAlign.right),
            _cell(context, expense.type.labelFr, flex: 1),
            _cell(context, expense.frequencyLabel, flex: 1),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Modifier',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error),
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext ctx, String text,
      {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(ctx).textTheme.bodySmall,
        textAlign: align,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

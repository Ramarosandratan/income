import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';
import '../../widgets.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTab = 0;

  final recurringListProvider = FutureProvider<List<RecurringTemplate>>(
      (ref) => ref.watch(recurringRepositoryProvider).list());

  String? _filterMemberId;
  String? _filterCategoryId;
  Set<ExpenseType> _filterTypes = {};
  String _searchQuery = '';
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Dépenses et récurrences',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              if (_currentTab == 0)
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nouvelle dépense'),
                  onPressed: () => _addExpense(context),
                ),
              if (_currentTab == 0)
                const SizedBox(width: 8),
              if (_currentTab == 0)
                OutlinedButton.icon(
                  icon: const Icon(Icons.category, size: 18),
                  label: const Text('Catégories'),
                  onPressed: () => _manageCategories(context),
                ),
              if (_currentTab == 0)
                const SizedBox(width: 8),
              if (_currentTab == 1)
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle récurrence'),
                  onPressed: () => _addRecurring(context),
                ),
              if (_currentTab == 0)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Rafraîchir',
                  onPressed: () => refreshAll(ref),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dépenses'),
              Tab(text: 'Récurrences'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseTab(),
                _buildRecurringTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTab() {
    final expenses = ref.watch(periodExpensesProvider);
    final members = ref.watch(membersProvider);
    final categories = ref.watch(categoriesProvider);

    final byId = {
      for (final m in members.valueOrNull ?? const <Profile>[]) m.id: m
    };
    final catById = {
      for (final c in categories.valueOrNull ?? const <Category>[]) c.id: c
    };

    final expenseCats =
        categories.valueOrNull?.where((c) => c.kind == EntryKind.expense).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
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
                    for (final m in members.valueOrNull ?? [])
                      DropdownMenuItem(value: m.id, child: Text(m.fullName)),
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
              SegmentedButton<ExpenseType>(
                segments: const [
                  ButtonSegment(
                      value: ExpenseType.daily, label: Text('Journalière')),
                  ButtonSegment(
                      value: ExpenseType.monthly, label: Text('Mensuelle')),
                  ButtonSegment(
                      value: ExpenseType.fixed, label: Text('Fixe')),
                ],
                selected: _filterTypes,
                onSelectionChanged: (s) =>
                    setState(() => _filterTypes = Set.of(s)),
                multiSelectionEnabled: true,
                emptySelectionAllowed: true,
                showSelectedIcon: false,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Recherche',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                ),
                tooltip: 'Ordre de tri',
                onPressed: () => setState(() => _sortAsc = !_sortAsc),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Résumé
        Row(
          children: [
            Text('${expenses.valueOrNull?.length ?? 0} dépenses',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        // Liste
        Expanded(
          child: expenses.when(
            data: (list) {
              var filtered = list.toList();
              if (_filterMemberId != null) {
                filtered = filtered
                    .where((e) => e.memberId == _filterMemberId)
                    .toList();
              }
              if (_filterCategoryId != null) {
                filtered = filtered
                    .where((e) => e.categoryId == _filterCategoryId)
                    .toList();
              }
              if (_filterTypes.isNotEmpty) {
                filtered = filtered
                    .where((e) => _filterTypes.contains(e.type))
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                filtered = filtered.where((e) {
                  final note = (e.note ?? '').toLowerCase();
                  final cat =
                      catById[e.categoryId]?.name.toLowerCase() ?? '';
                  final member =
                      byId[e.memberId]?.fullName.toLowerCase() ?? '';
                  return note.contains(_searchQuery) ||
                      cat.contains(_searchQuery) ||
                      member.contains(_searchQuery);
                }).toList();
              }

              filtered.sort((a, b) => _sortAsc
                  ? a.spentAt.compareTo(b.spentAt)
                  : b.spentAt.compareTo(a.spentAt));

              final total =
                  filtered.fold<double>(0, (s, e) => s + e.amount);

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
                        const SizedBox(width: 80),
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringTab() {
    final templates = ref.watch(recurringListProvider);
    final members = ref.watch(membersProvider);
    final byId = {
      for (final m in members.valueOrNull ?? const <Profile>[]) m.id: m
    };

    return AsyncView(
      value: templates,
      builder: (list) {
        if (list.isEmpty) {
          return const Center(
              child: Text('Aucune dépense fixe enregistrée.'));
        }
        return ListView(
          children: [
            for (final t in list)
              Card(
                child: SwitchListTile(
                  secondary: CircleAvatar(
                    child: Icon(t.kind == EntryKind.income
                        ? Icons.payments
                        : Icons.autorenew),
                  ),
                  title: Text(t.label),
                  subtitle: Text(
                    '${Money.format(t.amount)} · '
                    '${t.frequencyLabel} · '
                    '${byId[t.memberId]?.fullName ?? 'Membre'} · '
                    'prochaine : ${Period.labelFr(t.nextRun)}',
                  ),
                  value: t.active,
                  onChanged: (v) async {
                    await ref
                        .read(recurringRepositoryProvider)
                        .setActive(t.id, v);
                    ref.invalidate(recurringListProvider);
                  },
                ),
              ),
          ],
        );
      },
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

  Future<void> _manageCategories(BuildContext context) async {
    // navigation ou dialogue de gestion des catégories
  }

  // ── Ajout dépense ──────────────────────────────────────────────────────
  Future<void> _addExpense(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final allMembers = await ref.read(membersProvider.future);
    final categories = await ref.read(categoriesProvider.future);
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
                // Type
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

  // ── Ajout récurrence ───────────────────────────────────────────────────
  Future<void> _addRecurring(BuildContext context) async {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final allMembers = (await ref.read(membersProvider.future))
        .where((m) => m.role == UserRole.member)
        .toList();
    final cats = await ref.read(categoriesProvider.future);
    String? memberId = allMembers.isEmpty ? null : allMembers.first.id;
    String? categoryId;
    var frequency = Frequency.monthly;
    int? frequencyDay;
    int yearlyMonth = DateTime.now().month;
    var kind = EntryKind.expense;

    if (!context.mounted || memberId == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle récurrence'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Libellé (ex. Loyer)')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Montant', suffixText: '€'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EntryKind>(
                    initialValue: kind,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                          value: EntryKind.expense, child: Text('Dépense')),
                      DropdownMenuItem(
                          value: EntryKind.income, child: Text('Revenu')),
                    ],
                    onChanged: (v) => setState(() => kind = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: memberId,
                    decoration: const InputDecoration(labelText: 'Membre'),
                    items: [
                      for (final m in allMembers)
                        DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                    ],
                    onChanged: (v) => setState(() => memberId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Aucune')),
                      for (final c in cats)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Frequency>(
                    initialValue: frequency,
                    decoration: const InputDecoration(labelText: 'Fréquence'),
                    items: const [
                      DropdownMenuItem(
                          value: Frequency.monthly, child: Text('Mensuelle')),
                      DropdownMenuItem(
                          value: Frequency.weekly, child: Text('Hebdomadaire')),
                      DropdownMenuItem(
                          value: Frequency.yearly, child: Text('Annuelle')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        frequency = v!;
                        frequencyDay = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (frequency == Frequency.weekly)
                    DropdownButtonFormField<int>(
                      initialValue: frequencyDay ?? 1,
                      decoration: const InputDecoration(
                          labelText: 'Jour de la semaine'),
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
                          labelText: 'Jour du mois'),
                      items: [
                        for (int d = 1; d <= 31; d++)
                          DropdownMenuItem(value: d, child: Text('$d')),
                      ],
                      onChanged: (v) =>
                          setState(() => frequencyDay = v!),
                    ),
                  if (frequency == Frequency.yearly)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: frequencyDay ?? 1,
                            decoration: const InputDecoration(
                                labelText: 'Jour'),
                            items: [
                              for (int d = 1; d <= 31; d++)
                                DropdownMenuItem(value: d, child: Text('$d')),
                            ],
                            onChanged: (v) =>
                                setState(() => frequencyDay = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: DateTime.now().month,
                            decoration: const InputDecoration(
                                labelText: 'Mois'),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Janvier')),
                              DropdownMenuItem(value: 2, child: Text('Février')),
                              DropdownMenuItem(value: 3, child: Text('Mars')),
                              DropdownMenuItem(value: 4, child: Text('Avril')),
                              DropdownMenuItem(value: 5, child: Text('Mai')),
                              DropdownMenuItem(value: 6, child: Text('Juin')),
                              DropdownMenuItem(value: 7, child: Text('Juillet')),
                              DropdownMenuItem(value: 8, child: Text('Août')),
                              DropdownMenuItem(value: 9, child: Text('Septembre')),
                              DropdownMenuItem(value: 10, child: Text('Octobre')),
                              DropdownMenuItem(value: 11, child: Text('Novembre')),
                              DropdownMenuItem(value: 12, child: Text('Décembre')),
                            ],
                            onChanged: (v) =>
                                setState(() => yearlyMonth = v!),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final value =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                if (labelCtrl.text.trim().isEmpty || value <= 0) return;
                final profile = await ref.read(currentProfileProvider.future);

                final now = DateTime.now();
                DateTime nextRun;
                if (frequency == Frequency.yearly && frequencyDay != null) {
                  final d = frequencyDay!;
                  final y = now.month > yearlyMonth ||
                          (now.month == yearlyMonth && now.day >= d)
                      ? now.year + 1
                      : now.year;
                  final lastDay = DateTime(y, yearlyMonth + 1, 0).day;
                  nextRun = DateTime(y, yearlyMonth, d.clamp(1, lastDay).toInt());
                } else if (frequency == Frequency.monthly &&
                    frequencyDay != null) {
                  final d = frequencyDay!;
                  final nextMonth = DateTime(now.year, now.month + 1, 1);
                  final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
                  nextRun = DateTime(
                      nextMonth.year, nextMonth.month, d.clamp(1, lastDay).toInt());
                } else if (frequency == Frequency.weekly &&
                    frequencyDay != null) {
                  final d = frequencyDay!;
                  final diff = (d - now.weekday + 7) % 7;
                  nextRun = DateTime(now.year, now.month, now.day + (diff == 0 ? 7 : diff));
                } else {
                  nextRun = Period.next(ref.read(selectedPeriodProvider));
                }

                await ref.read(recurringRepositoryProvider).upsert(
                      RecurringTemplate(
                        id: '',
                        familyId: profile!.familyId,
                        memberId: memberId!,
                        categoryId: categoryId,
                        label: labelCtrl.text.trim(),
                        amount: value,
                        kind: kind,
                        frequency: frequency,
                        frequencyDay: frequencyDay,
                        nextRun: nextRun,
                      ),
                      profile.familyId,
                    );
                ref.invalidate(recurringListProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
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

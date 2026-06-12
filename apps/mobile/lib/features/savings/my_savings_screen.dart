import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../data.dart';

/// Objectifs d'épargne visibles par le membre (les siens + familiaux).
class MySavingsScreen extends ConsumerWidget {
  const MySavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(mySavingsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Épargne',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
            child: goals.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (list) => list.isEmpty
                  ? const Center(child: Text('Aucun objectif pour le moment.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final g in list)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.savings),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(g.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium)),
                                      if (g.memberId == null)
                                        const Chip(
                                            label: Text('Famille'),
                                            visualDensity:
                                                VisualDensity.compact),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: g.progress,
                                      minHeight: 10,
                                      color: g.isReached ? Colors.green : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                      '${Money.format(g.currentAmount)} / ${Money.format(g.targetAmount)}'
                                      '${g.isReached ? ' · atteint 🎉' : ''}'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:income_core/income_core.dart';

import '../../widgets.dart';

/// Provider qui génère des [Depense] de démonstration pour alimenter le
/// calendrier prévisionnel.
///
/// Utilise les dépenses récurrentes existantes si disponibles, ou un jeu de
/// données mockées représentatif.
final calendarDepensesProvider = Provider<List<Depense>>((ref) {
  // Quelques dépenses forfaitaires pour démontrer toutes les fréquences.
  final now = DateTime.now();
  final debutAnnee = DateTime(now.year, 1, 1);

  return [
    Depense(
      id: 'd1',
      titre: 'Loyer',
      natureMontant: NatureMontant.fixe,
      montantParDefaut: 1200.0,
      dateDebut: debutAnnee,
      frequence: const Frequence(
        type: TypeRecurrence.mensuel,
        intervalle: 1,
        parametres: [5], // le 5 de chaque mois
      ),
    ),
    Depense(
      id: 'd2',
      titre: 'Électricité (estimation)',
      natureMontant: NatureMontant.variable,
      montantParDefaut: 85.0,
      dateDebut: debutAnnee,
      frequence: const Frequence(
        type: TypeRecurrence.mensuel,
        intervalle: 1,
        parametres: [15], // le 15
      ),
    ),
    Depense(
      id: 'd3',
      titre: 'Forfait mobile',
      natureMontant: NatureMontant.fixe,
      montantParDefaut: 29.99,
      dateDebut: debutAnnee,
      frequence: const Frequence(
        type: TypeRecurrence.mensuel,
        intervalle: 1,
        parametres: [-1], // dernier jour du mois
      ),
    ),
    Depense(
      id: 'd4',
      titre: 'Cantine scolaire',
      natureMontant: NatureMontant.fixe,
      montantParDefaut: 12.50,
      dateDebut: debutAnnee,
      frequence: const Frequence(
        type: TypeRecurrence.hebdomadaire,
        intervalle: 1,
        parametres: [1, 3, 5], // lundi, mercredi, vendredi
      ),
    ),
    Depense(
      id: 'd5',
      titre: 'Assurance habitation',
      natureMontant: NatureMontant.fixe,
      montantParDefaut: 180.0,
      dateDebut: debutAnnee,
      frequence: const Frequence(
        type: TypeRecurrence.mensuel,
        intervalle: 3, // trimestriel (jan, avr, jul, oct)
        parametres: [1],
      ),
    ),
    Depense(
      id: 'd6',
      titre: 'Abonnement Netflix',
      natureMontant: NatureMontant.fixe,
      montantParDefaut: 13.99,
      dateDebut: debutAnnee,
      dateFin: DateTime(now.year, 6, 30), // se termine en juin
      frequence: const Frequence(
        type: TypeRecurrence.mensuel,
        intervalle: 1,
        parametres: [10], // le 10
      ),
    ),
    Depense(
      id: 'd7',
      titre: 'Prime annuelle',
      natureMontant: NatureMontant.variable,
      montantParDefaut: 500.0,
      dateDebut: debutAnnee,
      frequence: const Frequence(
        type: TypeRecurrence.mensuel,
        intervalle: 12, // une fois par an
        parametres: [1], // le 1er du mois anniversaire
      ),
    ),
    Depense(
      id: 'd8',
      titre: 'Ticket resto (estimation)',
      natureMontant: NatureMontant.variable,
      montantParDefaut: 8.50,
      dateDebut: debutAnnee,
      frequence: const Frequence(
        type: TypeRecurrence.journalier,
        intervalle: 2, // tous les 2 jours
      ),
    ),
    Depense(
      id: 'd9',
      titre: 'Frais de dossier (ponctuel)',
      natureMontant: NatureMontant.fixe,
      montantParDefaut: 35.0,
      dateDebut: DateTime(now.year, now.month, 15),
      frequence: const Frequence(
        type: TypeRecurrence.ponctuel,
      ),
    ),
    // Dépense avec rabattement : 31 partout → test mois courts
    Depense(
      id: 'd10',
      titre: 'Prêt (passage au 31)',
      natureMontant: NatureMontant.fixe,
      montantParDefaut: 450.0,
      dateDebut: DateTime(now.year, 1, 31),
      frequence: const Frequence(
        type: TypeRecurrence.mensuel,
        intervalle: 1,
        parametres: [31], // sera rabattu aux mois courts
      ),
    ),
  ];
});

/// Provider qui résout les occurrences du mois sélectionné.
final calendarOccurrencesProvider =
    FutureProvider<List<OccurrenceResolu>>((ref) async {
  final depenses = ref.watch(calendarDepensesProvider);
  final period = ref.watch(selectedPeriodProvider);
  const engine = CalendarEngine();

  return engine.genererMois(
    depenses: depenses,
    overrides: const [],
    anneeCible: period.year,
    moisCible: period.month,
  );
});

/// Statistiques du mois : total prévu, total confirmé, nombre d'occurrences.
final calendarStatsProvider = Provider<({double total, double confirme, int nbOccurrences})>(
  (ref) {
    final occurrences = ref.watch(calendarOccurrencesProvider).valueOrNull ?? [];
    double total = 0;
    double confirme = 0;
    for (final o in occurrences) {
      if (o.estInclusDansTotal) {
        total += o.montantFinal;
        if (o.statutUI == StatutUI.confirme) {
          confirme += o.montantFinal;
        }
      }
    }
    return (total: total, confirme: confirme, nbOccurrences: occurrences.length);
  },
);

/// Écran calendrier prévisionnel — affiche les occurrences du mois sous forme
/// de grille calendrier + liste détaillée.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrences = ref.watch(calendarOccurrencesProvider);
    final stats = ref.watch(calendarStatsProvider);
    final period = ref.watch(selectedPeriodProvider);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: scheme.primary, size: 28),
              const SizedBox(width: 12),
              Text('Calendrier prévisionnel — ${Period.labelFr(period)}',
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Projection des dépenses récurrentes du mois. '
            'Les montants fixés sont confirmés, les variables sont estimés.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          // ── Cartes de statistiques ─────────────────────────────────
          AsyncView(
            value: occurrences,
            builder: (_) => Row(
              children: [
                _MiniStatCard(
                  icon: Icons.receipt_long,
                  label: 'Dépenses prévues',
                  value: '${stats.nbOccurrences} occurrences',
                  color: scheme.primary,
                ),
                const SizedBox(width: 16),
                _MiniStatCard(
                  icon: Icons.euro,
                  label: 'Total estimé',
                  value: Money.format(stats.total),
                  color: scheme.tertiary,
                ),
                const SizedBox(width: 16),
                _MiniStatCard(
                  icon: Icons.check_circle,
                  label: 'Confirmé',
                  value: Money.format(stats.confirme),
                  color: Colors.green.shade600,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Grille calendrier + liste ──────────────────────────────
          Expanded(
            child: AsyncView(
              value: occurrences,
              builder: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64, color: scheme.outline),
                        const SizedBox(height: 16),
                        Text('Aucune occurrence pour ce mois.',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Grille mensuelle ────────────────────────────
                    SizedBox(
                      width: 340,
                      child: _CalendarGrid(
                        year: period.year,
                        month: period.month,
                        occurrences: list,
                      ),
                    ),
                    const SizedBox(width: 24),

                    // ── Liste détaillée ─────────────────────────────
                    Expanded(
                      child: _OccurrenceList(occurrences: list),
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
}

/// Mini carte statistique pour l'en-tête.
class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              radius: 20,
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Grille calendrier affichant chaque jour du mois avec les occurrences.
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.occurrences,
  });

  final int year;
  final int month;
  final List<OccurrenceResolu> occurrences;

  static const _jourSemaine = <String>['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    final premier = DateTime(year, month, 1);
    final dernier = DateTime(year, month + 1, 0);
    final nbJours = dernier.day;
    // Lundi = 1, Dimanche = 7 → décalage : lundi=0
    final decalage = premier.weekday - 1;

    // Index des occurrences par jour.
    final parJour = <int, List<OccurrenceResolu>>{};
    for (final o in occurrences) {
      (parJour[o.date.day] ??= []).add(o);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // En-tête des jours
            Row(
              children: [
                for (final j in _jourSemaine)
                  Expanded(
                    child: Center(
                      child: Text(j,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Grille des jours
            ...List.generate((nbJours + decalage + 6) ~/ 7, (semaine) {
              return Row(
                children: List.generate(7, (col) {
                  final jour = semaine * 7 + col - decalage + 1;
                  return Expanded(
                    child: jour < 1 || jour > nbJours
                        ? const SizedBox(height: 56)
                        : _CalendarDayCell(
                            day: jour,
                            occurrences: parJour[jour] ?? [],
                            isToday: year == DateTime.now().year &&
                                month == DateTime.now().month &&
                                jour == DateTime.now().day,
                          ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Cellule d'un jour dans la grille calendrier.
class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.occurrences,
    this.isToday = false,
  });

  final int day;
  final List<OccurrenceResolu> occurrences;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = occurrences
        .where((o) => o.estInclusDansTotal)
        .fold<double>(0, (s, o) => s + o.montantFinal);

    return Container(
      height: 56,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isToday
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : occurrences.isNotEmpty
                ? scheme.secondaryContainer.withValues(alpha: 0.3)
                : null,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: scheme.primary, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? scheme.primary : null,
                ),
          ),
          if (occurrences.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              Money.format(total).replaceAll(' €', ''),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Liste détaillée des occurrences du mois, triées par date.
class _OccurrenceList extends StatelessWidget {
  const _OccurrenceList({required this.occurrences});
  final List<OccurrenceResolu> occurrences;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Grouper par date.
    final groupes = <int, List<OccurrenceResolu>>{};
    for (final o in occurrences) {
      (groupes[o.date.day] ??= []).add(o);
    }

    // Trier les jours.
    final jours = groupes.keys.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Détail des occurrences',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            // Légende
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _LegendeItem(
                    color: Colors.green.shade600,
                    label: 'Confirmé (fixe/override)'),
                _LegendeItem(
                    color: Colors.orange.shade600,
                    label: 'Estimé (variable)'),
                _LegendeItem(
                    color: scheme.outline, label: 'Prévisionnel'),
                _LegendeItem(
                    color: Colors.red.shade400,
                    label: 'Suspendu'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (final jour in jours) ...[
                    // En-tête de jour
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        '$jour ${_nomMois(occurrences.first.date.month)} ${occurrences.first.date.year}',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Occurrences du jour
                    for (final o in groupes[jour]!)
                      _OccurrenceTile(occ: o),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nomMois(int m) {
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return mois[m - 1];
  }
}

/// Élément de légende.
class _LegendeItem extends StatelessWidget {
  const _LegendeItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Tuile d'une occurrence dans la liste détaillée.
class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({required this.occ});
  final OccurrenceResolu occ;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color statutColor;
    IconData statutIcon;
    String statutLabel;

    switch (occ.statutUI) {
      case StatutUI.confirme:
        statutColor = Colors.green.shade600;
        statutIcon = Icons.check_circle;
        statutLabel = 'Confirmé';
      case StatutUI.valideAuto:
        statutColor = Colors.orange.shade600;
        statutIcon = Icons.auto_awesome;
        statutLabel = 'Estimé (auto)';
      case StatutUI.previsionnel:
        statutColor = scheme.outline;
        statutIcon = Icons.schedule;
        statutLabel = 'Prévisionnel';
      case StatutUI.suspendu:
        statutColor = Colors.red.shade400;
        statutIcon = Icons.block;
        statutLabel = 'Suspendu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: statutColor.withValues(alpha: 0.15),
          child: Icon(statutIcon, size: 16, color: statutColor),
        ),
        title: Text(occ.titre,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                )),
        subtitle: Row(
          children: [
            Icon(Icons.euro, size: 12, color: scheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Text(
              Money.format(occ.montantFinal),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: occ.statutUI == StatutUI.suspendu
                        ? Colors.red.shade300
                        : null,
                    decoration: occ.statutUI == StatutUI.suspendu
                        ? TextDecoration.lineThrough
                        : null,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: statutColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statutLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statutColor,
                      fontSize: 10,
                    ),
              ),
            ),
            if (!occ.estInclusDansTotal) ...[
              const SizedBox(width: 8),
              Icon(Icons.block, size: 12, color: Colors.red.shade300),
              const SizedBox(width: 2),
              Text('Exclu',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.red.shade300,
                        fontSize: 10,
                      )),
            ],
          ],
        ),
      ),
    );
  }
}

import '../models/calendrier/action_override.dart';
import '../models/calendrier/depense.dart';
import '../models/calendrier/depense_override.dart';
import '../models/calendrier/frequence.dart';
import '../models/calendrier/nature_montant.dart';
import '../models/calendrier/occurrence_resolu.dart';

/// Moteur de calendrier financier.
///
/// Résout les occurrences de dépenses récurrentes pour un mois cible en
/// appliquant la cascade logique : récurrence → override → statut.
///
/// Gère nativement :
/// - les années bissextiles et les mois courts
/// - le rabattement des jours 29-31 sur le dernier jour du mois
/// - le cas spécial -1 (dernier jour du mois)
/// - les intervalles multiplicateurs (ex: mensuel + 3 = trimestriel)
class CalendarEngine {
  const CalendarEngine();

  /// Génère toutes les occurrences résolues pour le mois cible.
  ///
  /// [depenses] : liste des règles de récurrence parentes.
  /// [overrides] : liste des exceptions (modifications / suppressions).
  /// [anneeCible] : année du mois à générer (ex: 2024).
  /// [moisCible] : mois à générer (1 = janvier … 12 = décembre).
  ///
  /// Retourne une liste plate d'[OccurrenceResolu] triée par date croissante,
  /// une par occurrence résolue dans le mois.
  List<OccurrenceResolu> genererMois({
    required List<Depense> depenses,
    required List<DepenseOverride> overrides,
    required int anneeCible,
    required int moisCible,
  }) {
    final aujourdhui = DateTime.now();
    final premierDuMois = DateTime(anneeCible, moisCible, 1);
    final dernierDuMois = DateTime(anneeCible, moisCible + 1, 0);
    final nbJours = dernierDuMois.day;

    // Index des overrides par (id_depense, date_occurrence) pour lookup rapide.
    final overrideIndex = <String, DepenseOverride>{};
    for (final ov in overrides) {
      final cle = _cleOverride(ov.idDepense, ov.dateOccurrence);
      overrideIndex[cle] = ov;
    }

    final resultats = <OccurrenceResolu>[];

    // Pour chaque dépense active, on parcourt les jours du mois.
    for (final d in depenses) {
      // Filtrer : la dépense doit être active sur ce mois.
      if (!_estActiveSurMois(d, premierDuMois, dernierDuMois)) continue;

      // Parcourir chaque jour du mois.
      for (var jour = 1; jour <= nbJours; jour++) {
        final dateCourante = DateTime(anneeCible, moisCible, jour);

        if (!_correspondRecurrence(d, dateCourante)) continue;

        // Cascade logique : override ?
        final cle = _cleOverride(d.id, dateCourante);
        final override = overrideIndex[cle];

        OccurrenceResolu occurrence;
        if (override != null && override.action == ActionOverride.suppression) {
          occurrence = OccurrenceResolu(
            idDepense: d.id,
            date: dateCourante,
            titre: d.titre,
            montantFinal: 0,
            statutUI: StatutUI.suspendu,
            estInclusDansTotal: false,
            categoryId: d.categoryId,
          );
        } else if (override != null &&
            override.action == ActionOverride.modification) {
          occurrence = OccurrenceResolu(
            idDepense: d.id,
            date: dateCourante,
            titre: d.titre,
            montantFinal: override.montantOverride ?? d.montantParDefaut,
            statutUI: _deduireStatut(dateCourante, aujourdhui,
                d.natureMontant, StatutUI.confirme),
            estInclusDansTotal: true,
            categoryId: d.categoryId,
          );
        } else {
          // Aucun override : montant par défaut.
          final statut = _deduireStatut(
              dateCourante, aujourdhui, d.natureMontant, null);
          occurrence = OccurrenceResolu(
            idDepense: d.id,
            date: dateCourante,
            titre: d.titre,
            montantFinal: d.montantParDefaut,
            statutUI: statut,
            estInclusDansTotal: statut != StatutUI.suspendu,
            categoryId: d.categoryId,
          );
        }

        resultats.add(occurrence);
      }
    }

    // Tri par date croissante.
    resultats.sort((a, b) => a.date.compareTo(b.date));
    return resultats;
  }

  // ── Helpers privés ──────────────────────────────────────────────────

  /// Vérifie si une dépense est active sur au moins un jour du mois cible.
  bool _estActiveSurMois(
      Depense d, DateTime premierDuMois, DateTime dernierDuMois) {
    if (d.dateDebut.isAfter(dernierDuMois)) return false;
    if (d.dateFin != null && d.dateFin!.isBefore(premierDuMois)) return false;
    return true;
  }

  /// Vérifie si [date] est une occurrence valide de la récurrence [d].
  bool _correspondRecurrence(Depense d, DateTime date) {
    // PONCTUEL : uniquement le jour même de date_debut.
    if (d.frequence.type == TypeRecurrence.ponctuel) {
      return _memeJour(date, d.dateDebut);
    }

    // Si la date est avant date_debut, pas d'occurrence.
    if (date.isBefore(d.dateDebut)) return false;

    // Si la date est après date_fin, pas d'occurrence.
    if (d.dateFin != null && date.isAfter(d.dateFin!)) return false;

    return switch (d.frequence.type) {
      TypeRecurrence.journalier => _estOccurrenceJournaliere(d, date),
      TypeRecurrence.hebdomadaire => _estOccurrenceHebdomadaire(d, date),
      TypeRecurrence.mensuel => _estOccurrenceMensuelle(d, date),
      // PONCTUEL est déjà traité par le return précoce ci-dessus.
      TypeRecurrence.ponctuel => false,
    };
  }

  /// JOURNALIER : la différence en jours depuis date_debut est multiple de
  /// l'intervalle.
  bool _estOccurrenceJournaliere(Depense d, DateTime date) {
    final ecartJours = date.difference(d.dateDebut).inDays;
    return ecartJours % d.frequence.intervalle == 0;
  }

  /// HEBDOMADAIRE : le jour de la semaine est dans parametres ET la semaine
  /// est un multiple de l'intervalle depuis la semaine de départ.
  bool _estOccurrenceHebdomadaire(Depense d, DateTime date) {
    final params = d.frequence.parametres;
    if (params == null || params.isEmpty) return false;

    // ISO 8601 : DateTime.monday=1 … DateTime.sunday=7
    if (!params.contains(date.weekday)) return false;

    // Si intervalle == 1, toutes les semaines conviennent.
    if (d.frequence.intervalle <= 1) return true;

    // Numéro de semaine relative depuis date_debut.
    final ecartJours = date.difference(d.dateDebut).inDays;
    final semaineRel = ecartJours ~/ 7;
    return semaineRel % d.frequence.intervalle == 0;
  }

  /// MENSUEL : le jour du mois est dans parametres (avec rabattement) ET
  /// le nombre de mois depuis date_debut est multiple de l'intervalle.
  bool _estOccurrenceMensuelle(Depense d, DateTime date) {
    final params = d.frequence.parametres;
    if (params == null || params.isEmpty) return false;

    // L'occurrence doit tomber sur le bon mois (intervalle mensuel).
    if (!_estBonMois(d, date)) return false;

    // Recherche du jour cible dans les paramètres.
    // -1 = dernier jour du mois.
    final cible = params.first;
    final dernierJour = DateTime(date.year, date.month + 1, 0).day;

    int jourAttendu;
    if (cible == -1) {
      jourAttendu = dernierJour;
    } else {
      // Rabattement : si le jour demandé dépasse la longueur du mois,
      // on prend le dernier jour valide.
      jourAttendu = cible > dernierJour ? dernierJour : cible;
    }

    return date.day == jourAttendu;
  }

  /// Vérifie si [date] est dans le bon cycle mensuel par rapport à date_debut
  /// et à l'intervalle.
  bool _estBonMois(Depense d, DateTime date) {
    final moisDepuisDebut = (date.year - d.dateDebut.year) * 12 +
        (date.month - d.dateDebut.month);
    return moisDepuisDebut % d.frequence.intervalle == 0;
  }

  /// Déduit le [StatutUI] d'une occurrence par rapport à aujourd'hui.
  ///
  /// [overrideForce] : si non null, le statut est forcé (cas override =
  /// MODIFICATION → CONFIRME).
  StatutUI _deduireStatut(
    DateTime date,
    DateTime aujourdhui,
    NatureMontant natureMontant,
    StatutUI? overrideForce,
  ) {
    if (overrideForce != null) return overrideForce;

    if (date.isAfter(aujourdhui)) {
      return StatutUI.previsionnel;
    }

    // Date ≤ aujourd'hui
    return switch (natureMontant) {
      NatureMontant.fixe => StatutUI.confirme,
      NatureMontant.variable => StatutUI.valideAuto,
    };
  }

  /// Deux dates sont-elles le même jour (AAAA-MM-JJ) ?
  bool _memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Clé de lookup pour l'index des overrides.
  String _cleOverride(String idDepense, DateTime date) =>
      '$idDepense|${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

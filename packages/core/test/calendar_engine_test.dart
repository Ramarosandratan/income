import 'package:test/test.dart';
import 'package:income_core/src/models/calendrier/action_override.dart';
import 'package:income_core/src/models/calendrier/depense.dart';
import 'package:income_core/src/models/calendrier/depense_override.dart';
import 'package:income_core/src/models/calendrier/frequence.dart';
import 'package:income_core/src/models/calendrier/nature_montant.dart';
import 'package:income_core/src/models/calendrier/occurrence_resolu.dart';
import 'package:income_core/src/services/calendar_engine.dart';

void main() {
  const engine = CalendarEngine();
  final aujourdhui = DateTime.now();

  // ── Groupe : Année bissextile — Février 2024 ──────────────────────────
  group('Février 2024 (année bissextile, 29 jours)', () {
    const annee = 2024;
    const mois = 2; // Février

    test('mensuel au 31 → rabattu au 29 (dernier jour de février 2024)', () {
      // Dépense mensuelle paramétrée au 31.
      final dep = Depense(
        id: 'd1',
        titre: 'Loyer',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 1200.0,
        dateDebut: DateTime(2024, 1, 1),
        frequence: const Frequence(
          type: TypeRecurrence.mensuel,
          intervalle: 1,
          parametres: [31],
        ),
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: annee,
        moisCible: mois,
      );

      // Le 31 n'existe pas en février → rabattu au 29 (dernier jour).
      expect(resultats.length, 1,
          reason: 'Une seule occurrence rabattue au 29 février');
      expect(resultats.first.date.day, 29,
          reason: 'Rabattement sur le dernier jour du mois (29)');
      expect(resultats.first.montantFinal, 1200.0);
      expect(resultats.first.statutUI,
          aujourdhui.isAfter(DateTime(2024, 2, 29))
              ? StatutUI.confirme
              : StatutUI.previsionnel);
      expect(resultats.first.estInclusDansTotal, true);
    });

    test('mensuel au -1 → dernier jour du mois (29 février 2024)', () {
      final dep = Depense(
        id: 'd2',
        titre: 'Forfait mobile',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 30.0,
        dateDebut: DateTime(2024, 1, 1),
        frequence: const Frequence(
          type: TypeRecurrence.mensuel,
          intervalle: 1,
          parametres: [-1], // dernier jour du mois
        ),
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: annee,
        moisCible: mois,
      );

      expect(resultats.length, 1);
      expect(resultats.first.date.day, 29,
          reason: '-1 doit donner le dernier jour = 29 février 2024');
      expect(resultats.first.montantFinal, 30.0);
    });

    test('dépense variable passée sans override → statut VALIDE_AUTO', () {
      // Dépense mensuelle au 15, montant VARIABLE.
      final dep = Depense(
        id: 'd3',
        titre: 'Électricité',
        natureMontant: NatureMontant.variable,
        montantParDefaut: 80.0,
        dateDebut: DateTime(2024, 1, 15),
        frequence: const Frequence(
          type: TypeRecurrence.mensuel,
          intervalle: 1,
          parametres: [15],
        ),
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: annee,
        moisCible: mois,
      );

      expect(resultats.length, 1,
          reason: 'Une occurrence le 15 février 2024');
      expect(resultats.first.date.day, 15);
      expect(resultats.first.montantFinal, 80.0,
          reason: 'Montant par défaut (aucun override)');
      expect(resultats.first.statutUI,
          aujourdhui.isAfter(DateTime(2024, 2, 15))
              ? StatutUI.valideAuto
              : StatutUI.previsionnel,
          reason: 'Variable sans override → VALIDE_AUTO si date ≤ aujourd\'hui');
      expect(resultats.first.estInclusDansTotal, true);
    });

    test('override SUPPRESSION → statut SUSPENDU, exclus du total', () {
      // Dépense mensuelle fixe au 20.
      final dep = Depense(
        id: 'd4',
        titre: 'Assurance',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 50.0,
        dateDebut: DateTime(2024, 1, 20),
        frequence: const Frequence(
          type: TypeRecurrence.mensuel,
          intervalle: 1,
          parametres: [20],
        ),
      );

      // Override de SUPPRESSION pour le 20 février 2024.
      final override = DepenseOverride(
        idDepense: 'd4',
        dateOccurrence: DateTime(2024, 2, 20),
        action: ActionOverride.suppression,
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: [override],
        anneeCible: annee,
        moisCible: mois,
      );

      expect(resultats.length, 1, reason: 'Occurrence présente mais supprimée');
      expect(resultats.first.date.day, 20);
      expect(resultats.first.montantFinal, 0,
          reason: 'Montant à 0 car supprimé');
      expect(resultats.first.statutUI, StatutUI.suspendu,
          reason: 'Override suppression → SUSPENDU');
      expect(resultats.first.estInclusDansTotal, false,
          reason: 'Exclu du total');
    });

    test('override MODIFICATION → montant modifié, statut CONFIRME', () {
      final dep = Depense(
        id: 'd5',
        titre: 'Courses',
        natureMontant: NatureMontant.variable,
        montantParDefaut: 300.0,
        dateDebut: DateTime(2024, 1, 10),
        frequence: const Frequence(
          type: TypeRecurrence.mensuel,
          intervalle: 1,
          parametres: [10],
        ),
      );

      final override = DepenseOverride(
        idDepense: 'd5',
        dateOccurrence: DateTime(2024, 2, 10),
        action: ActionOverride.modification,
        montantOverride: 250.0,
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: [override],
        anneeCible: annee,
        moisCible: mois,
      );

      expect(resultats.length, 1);
      expect(resultats.first.montantFinal, 250.0,
          reason: 'Montant override (250 au lieu de 300)');
      expect(resultats.first.statutUI, StatutUI.confirme,
          reason: 'Override modification → CONFIRME');
      expect(resultats.first.estInclusDansTotal, true);
    });
  });

  // ── Groupe : Fréquence hebdomadaire ─────────────────────────────────────
  group('Fréquence hebdomadaire', () {
    test('tous les lundis et jeudis (intervalle 1)', () {
      // Dépense hebdomadaire les lundi (1) et jeudi (4), intervalle 1.
      final dep = Depense(
        id: 'w1',
        titre: 'Cantine',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 15.0,
        dateDebut: DateTime(2024, 1, 1), // Un lundi
        frequence: const Frequence(
          type: TypeRecurrence.hebdomadaire,
          intervalle: 1,
          parametres: [1, 4], // lundi, jeudi
        ),
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 1, // Janvier 2024
      );

      // Janvier 2024 : lundis = 1, 8, 15, 22, 29 ; jeudis = 4, 11, 18, 25
      // Total = 9 occurrences
      expect(resultats.length, 9,
          reason: '5 lundis + 4 jeudis en janvier 2024');

      // Vérifier quelques occurrences clés.
      expect(resultats[0].date.day, 1);
      expect(resultats[0].titre, 'Cantine');
      expect(resultats[0].montantFinal, 15.0);

      expect(resultats[1].date.day, 4);
      expect(resultats[2].date.day, 8);
      expect(resultats[4].date.day, 15);

      // Toutes incluses dans le total.
      expect(resultats.every((o) => o.estInclusDansTotal), true);
    });

    test('tous les 15 jours le mercredi (intervalle 2)', () {
      // Dépense toutes les 2 semaines le mercredi (3).
      final dep = Depense(
        id: 'w2',
        titre: 'Netflix',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 12.0,
        dateDebut: DateTime(2024, 1, 3), // Un mercredi
        frequence: const Frequence(
          type: TypeRecurrence.hebdomadaire,
          intervalle: 2,
          parametres: [3], // mercredi
        ),
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 1,
      );

      // Janvier 2024 : mercredis = 3, 10, 17, 24, 31
      // Avec intervalle 2 depuis le 3 : 3, 17, 31
      expect(resultats.length, 3,
          reason: '3 mercredis sur 2 semaines (3, 17, 31)');
      expect(resultats[0].date.day, 3);
      expect(resultats[1].date.day, 17);
      expect(resultats[2].date.day, 31);
    });
  });

  // ── Groupe : Fréquence journalière ──────────────────────────────────────
  group('Fréquence journalière', () {
    test('tous les 3 jours', () {
      final dep = Depense(
        id: 'j1',
        titre: 'Ticket resto',
        natureMontant: NatureMontant.variable,
        montantParDefaut: 10.0,
        dateDebut: DateTime(2024, 2, 1),
        frequence: const Frequence(
          type: TypeRecurrence.journalier,
          intervalle: 3,
        ),
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 2,
      );

      // Février 2024 (29 jours), tous les 3 jours depuis le 1er :
      // 1, 4, 7, 10, 13, 16, 19, 22, 25, 28 → 10 occurrences
      expect(resultats.length, 10,
          reason: '10 occurrences (1, 4, 7, 10, 13, 16, 19, 22, 25, 28)');
      expect(resultats.first.date.day, 1);
      expect(resultats.last.date.day, 28);
    });
  });

  // ── Groupe : Fréquence mensuelle avec intervalle ────────────────────────
  group('Intervalle mensuel', () {
    test('trimestriel au 15 (mensuel + intervalle 3)', () {
      final dep = Depense(
        id: 'm1',
        titre: 'Assurance habitation',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 200.0,
        dateDebut: DateTime(2024, 1, 15),
        frequence: const Frequence(
          type: TypeRecurrence.mensuel,
          intervalle: 3, // trimestriel
          parametres: [15],
        ),
      );

      // En 2024 : janvier (déjà passé), avril, juillet, octobre.
      // On teste juillet 2024.
      var resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 7, // Juillet
      );

      expect(resultats.length, 1,
          reason: '1 occurrence en juillet (trimestriel)');
      expect(resultats.first.date.day, 15);

      // Février ne devrait PAS avoir d'occurrence (intervalle 3 depuis janvier).
      resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 2,
      );
      expect(resultats.length, 0,
          reason: 'Pas d\'occurrence en février (intervalle 3, prochain = avril)');
    });
  });

  // ── Groupe : Date de fin ────────────────────────────────────────────────
  group('Date de fin', () {
    test('occurrence avant date_fin incluse', () {
      final dep = Depense(
        id: 'e1',
        titre: 'Abonnement',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 10.0,
        dateDebut: DateTime(2024, 1, 1),
        dateFin: DateTime(2024, 3, 15), // se termine le 15 mars
        frequence: const Frequence(
          type: TypeRecurrence.mensuel,
          parametres: [1],
        ),
      );

      // Mars 2024 : le 1er mars est ≤ 15 mars → occurrence.
      var resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 3,
      );
      expect(resultats.length, 1, reason: 'Le 1er mars ≤ date_fin');

      // Avril 2024 : après date_fin → pas d'occurrence.
      resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 4,
      );
      expect(resultats.length, 0, reason: 'Avril après date_fin');
    });
  });

  // ── Groupe : Dépense ponctuelle ─────────────────────────────────────────
  group('Dépense ponctuelle', () {
    test('occurrence unique à date_debut', () {
      final dep = Depense(
        id: 'p1',
        titre: 'Frais dossier',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 35.0,
        dateDebut: DateTime(2024, 6, 15),
        frequence: const Frequence(
          type: TypeRecurrence.ponctuel,
        ),
      );

      // Juin 2024 : doit avoir l'occurrence.
      var resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 6,
      );
      expect(resultats.length, 1,
          reason: 'Occurrence ponctuelle en juin');
      expect(resultats.first.date.day, 15);

      // Juillet : plus d'occurrence.
      resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 7,
      );
      expect(resultats.length, 0, reason: 'Pas d\'occurrence en juillet');
    });
  });

  // ── Groupe : Mois courts (31 rabattu) ───────────────────────────────────
  group('Rabattement mois courts', () {
    test('mensuel au 31 en novembre (30 jours) → 30', () {
      final dep = Depense(
        id: 'r1',
        titre: 'Forfait',
        natureMontant: NatureMontant.fixe,
        montantParDefaut: 25.0,
        dateDebut: DateTime(2024, 1, 31),
        frequence: const Frequence(
          type: TypeRecurrence.mensuel,
          parametres: [31],
        ),
      );

      final resultats = engine.genererMois(
        depenses: [dep],
        overrides: const [],
        anneeCible: 2024,
        moisCible: 11, // Novembre (30 jours)
      );

      expect(resultats.length, 1,
          reason: 'Occurrence rabattue au 30 novembre');
      expect(resultats.first.date.day, 30,
          reason: '31 → rabattu à 30');
    });
  });
}

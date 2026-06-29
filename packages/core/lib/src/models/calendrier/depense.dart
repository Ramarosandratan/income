import 'frequence.dart';
import 'nature_montant.dart';

/// Entité A — Règle de récurrence parente.
///
/// Définit une dépense récurrente avec sa fréquence et son montant par défaut.
/// Les occurrences sont ensuite résolues par [CalendarEngine].
class Depense {
  const Depense({
    required this.id,
    required this.titre,
    required this.natureMontant,
    required this.montantParDefaut,
    required this.dateDebut,
    this.dateFin,
    this.frequence = const Frequence(type: TypeRecurrence.mensuel),
  }) : assert(montantParDefaut >= 0, 'Le montant ne peut pas être négatif');

  /// Identifiant unique de la dépense récurrente.
  final String id;

  /// Libellé de la dépense (ex: « Loyer », « Assurance auto »).
  final String titre;

  /// Nature du montant : fixe (toujours identique) ou variable (estimé).
  final NatureMontant natureMontant;

  /// Montant par défaut utilisé quand aucun override n'est présent.
  final double montantParDefaut;

  /// Date de début de la récurrence (incluse).
  final DateTime dateDebut;

  /// Date de fin optionnelle (incluse). null = récurrence infinie.
  final DateTime? dateFin;

  /// Configuration de la fréquence de récurrence.
  final Frequence frequence;

  factory Depense.fromJson(Map<String, dynamic> json) => Depense(
        id: json['id'] as String,
        titre: json['titre'] as String,
        natureMontant: NatureMontant.fromString(json['nature_montant'] as String),
        montantParDefaut: (json['montant_par_defaut'] as num).toDouble(),
        dateDebut: DateTime.parse(json['date_debut'] as String),
        dateFin: json['date_fin'] != null
            ? DateTime.parse(json['date_fin'] as String)
            : null,
        frequence: Frequence.fromJson(json['frequence'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'nature_montant': natureMontant.name.toUpperCase(),
        'montant_par_defaut': montantParDefaut,
        'date_debut': dateDebut.toIso8601String(),
        if (dateFin != null) 'date_fin': dateFin!.toIso8601String(),
        'frequence': frequence.toJson(),
      };
}

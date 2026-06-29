/// Statut d'affichage d'une occurrence résolue.
///
/// Déduit dynamiquement par rapport à la date du jour.
enum StatutUI {
  /// Date dans le futur : l'occurrence est une prévision.
  previsionnel,

  /// Date passée ou aujourd'hui : montant confirmé (fixe ou override).
  confirme,

  /// Date passée ou aujourd'hui, montant variable sans override :
  /// on accepte l'estimation par défaut (optimistic UI).
  valideAuto,

  /// L'occurrence a été supprimée par un override.
  suspendu;

  static StatutUI fromString(String v) => switch (v.toUpperCase()) {
        'PREVISIONNEL' => StatutUI.previsionnel,
        'CONFIRME' => StatutUI.confirme,
        'VALIDE_AUTO' => StatutUI.valideAuto,
        'SUSPENDU' => StatutUI.suspendu,
        _ => StatutUI.previsionnel,
      };
}

/// Occurrence résolue — résultat du moteur de calendrier pour une date donnée.
///
/// Après application de la cascade logique (récurrence → override → statut),
/// une occurrence est soit incluse dans le total du mois, soit suspendue.
class OccurrenceResolu {
  const OccurrenceResolu({
    required this.idDepense,
    required this.date,
    required this.titre,
    required this.montantFinal,
    required this.statutUI,
    required this.estInclusDansTotal,
    this.categoryId,
  });

  /// Référence vers [Depense.id] d'origine.
  final String idDepense;

  /// Date de l'occurrence (AAAA-MM-JJ).
  final DateTime date;

  /// Libellé de la dépense (recopié depuis [Depense.titre]).
  final String titre;

  /// Montant final après application de la cascade logique.
  /// 0 si l'occurrence est supprimée.
  final double montantFinal;

  /// Statut d'affichage déduit par rapport à aujourd'hui.
  final StatutUI statutUI;

  /// true si cette occurrence doit être comptée dans les totaux du mois.
  final bool estInclusDansTotal;

  /// Identifiant de la catégorie associée (optionnel).
  final String? categoryId;

  factory OccurrenceResolu.fromJson(Map<String, dynamic> json) =>
      OccurrenceResolu(
        idDepense: json['id_depense'] as String,
        date: DateTime.parse(json['date'] as String),
        titre: json['titre'] as String,
        montantFinal: (json['montant_final'] as num).toDouble(),
        statutUI: StatutUI.fromString(json['statut_ui'] as String),
        estInclusDansTotal: json['est_inclus_dans_total'] as bool,
        categoryId: json['category_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id_depense': idDepense,
        'date': date.toIso8601String(),
        'titre': titre,
        'montant_final': montantFinal,
        'statut_ui': statutUI.name.toUpperCase(),
        'est_inclus_dans_total': estInclusDansTotal,
        if (categoryId != null) 'category_id': categoryId,
      };
}

import 'action_override.dart';

/// Entité B — Table des exceptions.
///
/// Stocke les modifications ou suppressions appliquées à une occurrence
/// précise d'une dépense récurrente.
class DepenseOverride {
  const DepenseOverride({
    required this.idDepense,
    required this.dateOccurrence,
    required this.action,
    this.montantOverride,
  }) : assert(
          action != ActionOverride.suppression || montantOverride == null,
          'Une suppression ne peut pas avoir de montant_override',
        );

  /// Référence vers [Depense.id].
  final String idDepense;

  /// Date de l'occurrence ciblée (AAAA-MM-JJ).
  final DateTime dateOccurrence;

  /// Action à appliquer : modification ou suppression.
  final ActionOverride action;

  /// Nouveau montant si [action] == MODIFICATION, null sinon.
  final double? montantOverride;

  factory DepenseOverride.fromJson(Map<String, dynamic> json) =>
      DepenseOverride(
        idDepense: json['id_depense'] as String,
        dateOccurrence: DateTime.parse(json['date_occurrence'] as String),
        action: ActionOverride.fromString(json['action'] as String),
        montantOverride: (json['montant_override'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id_depense': idDepense,
        'date_occurrence': dateOccurrence.toIso8601String(),
        'action': action.name.toUpperCase(),
        if (montantOverride != null) 'montant_override': montantOverride,
      };
}

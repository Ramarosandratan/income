/// Type de récurrence d'une dépense.
enum TypeRecurrence {
  journalier,
  hebdomadaire,
  mensuel,
  ponctuel;

  static TypeRecurrence fromString(String v) => switch (v.toUpperCase()) {
        'JOURNALIER' => TypeRecurrence.journalier,
        'HEBDOMADAIRE' => TypeRecurrence.hebdomadaire,
        'MENSUEL' => TypeRecurrence.mensuel,
        'PONCTUEL' => TypeRecurrence.ponctuel,
        _ => TypeRecurrence.mensuel,
      };
}

/// Configuration de la fréquence de récurrence d'une dépense.
///
/// ## Règles
/// - `intervalle` ≥ 1, sert de multiplicateur
///   (ex: MENSUEL + intervalle 3 = trimestriel)
/// - JOURNALIER / PONCTUEL → `parametres` est null
/// - HEBDOMADAIRE → `parametres` contient un tableau d'entiers 1..7
///   (norme ISO 8601 : 1=lundi, 7=dimanche)
/// - MENSUEL → `parametres` contient un tableau d'un entier 1..31
///   La valeur -1 désigne le **dernier jour du mois**.
///   Si la valeur dépasse le nombre de jours du mois, l'occurrence est
///   rabattue sur le dernier jour valide.
class Frequence {
  const Frequence({
    required this.type,
    this.intervalle = 1,
    this.parametres,
  }) : assert(intervalle >= 1, 'L\'intervalle doit être ≥ 1');

  final TypeRecurrence type;
  final int intervalle;
  final List<int>? parametres;

  factory Frequence.fromJson(Map<String, dynamic> json) => Frequence(
        type: TypeRecurrence.fromString(json['type'] as String),
        intervalle: (json['intervalle'] as num?)?.toInt() ?? 1,
        parametres: json['parametres'] != null
            ? (json['parametres'] as List).cast<int>()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name.toUpperCase(),
        'intervalle': intervalle,
        if (parametres != null) 'parametres': parametres,
      };
}

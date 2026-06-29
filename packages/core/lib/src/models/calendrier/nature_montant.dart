/// Nature d'un montant : fixe (toujours le même) ou variable (estimé).
enum NatureMontant {
  fixe,
  variable;

  static NatureMontant fromString(String v) => switch (v.toUpperCase()) {
        'FIXE' => NatureMontant.fixe,
        'VARIABLE' => NatureMontant.variable,
        _ => NatureMontant.variable,
      };
}

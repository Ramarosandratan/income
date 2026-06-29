/// Action appliquée à une occurrence par un override.
enum ActionOverride {
  modification,
  suppression;

  static ActionOverride fromString(String v) => switch (v.toUpperCase()) {
        'MODIFICATION' => ActionOverride.modification,
        'SUPPRESSION' => ActionOverride.suppression,
        _ => ActionOverride.modification,
      };
}

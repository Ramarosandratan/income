import 'package:intl/intl.dart';

/// Une « période » est un mois budgétaire, représenté en base par une `date`
/// fixée au 1er du mois (ex. 2026-06-01).
class Period {
  /// Normalise une date au 1er de son mois.
  static DateTime monthOf(DateTime d) => DateTime(d.year, d.month, 1);

  /// Période du mois courant.
  static DateTime current() => monthOf(DateTime.now());

  /// Mois suivant.
  static DateTime next(DateTime period) =>
      DateTime(period.year, period.month + 1, 1);

  /// Mois précédent.
  static DateTime previous(DateTime period) =>
      DateTime(period.year, period.month - 1, 1);

  /// Sérialisation vers une `date` SQL (yyyy-MM-dd).
  static String toSql(DateTime period) =>
      DateFormat('yyyy-MM-dd').format(monthOf(period));

  /// Parse une `date` SQL ou un timestamp en période (1er du mois).
  static DateTime fromSql(String value) => monthOf(DateTime.parse(value));

  /// Libellé lisible, ex. « juin 2026 ».
  static String labelFr(DateTime period) =>
      DateFormat.yMMMM('fr_FR').format(period);
}

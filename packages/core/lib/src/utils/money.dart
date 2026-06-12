import 'package:intl/intl.dart';

/// Formatage monétaire (EUR, locale FR par défaut).
class Money {
  static final NumberFormat _fmt =
      NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);

  static String format(num amount) => _fmt.format(amount);

  /// Sans décimales, pour les libellés compacts (ex. cartes de synthèse).
  static String compact(num amount) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0)
          .format(amount);
}

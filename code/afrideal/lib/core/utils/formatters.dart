import 'package:intl/intl.dart';

/// Formatage des montants en Francs CFA (FCFA), la devise utilisée
/// partout sur la plateforme.
///
/// Exemple : Formatters.currency(85000) → "85 000 FCFA"
class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.decimalPattern('fr_FR');

  static String currency(num amount) {
    return '${_currencyFormat.format(amount)} FCFA';
  }

  /// Identique à [currency] mais sans le suffixe, pour les cas où le
  /// "FCFA" est déjà affiché séparément dans l'interface.
  static String number(num amount) {
    return _currencyFormat.format(amount);
  }

  /// Date courte lisible, ex: "13 Jan 2026"
  static String shortDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'fr_FR').format(date);
  }

  /// Date avec heure, ex: "13 Jan · 10h14"
  static String dateWithTime(DateTime date) {
    return '${DateFormat('d MMM', 'fr_FR').format(date)} · ${DateFormat('HH').format(date)}h${DateFormat('mm').format(date)}';
  }

  /// Date relative simple, ex: "Aujourd'hui", "Hier", ou date complète.
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    if (diff < 7) return DateFormat('EEEE', 'fr_FR').format(date);
    return shortDate(date);
  }

  /// Calcule le montant net reçu par le vendeur après commission.
  static double netAfterCommission(double price, double commissionRatePercent) {
    return price - (price * commissionRatePercent / 100);
  }
}

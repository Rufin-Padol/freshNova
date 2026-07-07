import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

/// Service centralisant l'initialisation de la base de données locale
/// Hive et l'ouverture de toutes les "box" (équivalent de tables) au
/// démarrage de l'application.
///
/// Toutes les box sont de type `Box<String>` : chaque enregistrement
/// est stocké comme une chaîne JSON (voir [LocalJsonStore]). Ce choix
/// élimine le besoin d'enregistrer un quelconque TypeAdapter Hive et
/// fonctionne de façon identique sur Android, iOS et Web.
class HiveService {
  HiveService._();

  static bool _initialized = false;

  /// Initialise Hive et ouvre toutes les box de l'application.
  /// Doit être appelé une seule fois, avant runApp(), depuis main.dart.
  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox<String>(StorageKeys.usersBox),
      Hive.openBox<String>(StorageKeys.productsBox),
      Hive.openBox<String>(StorageKeys.sellerRequestsBox),
      Hive.openBox<String>(StorageKeys.ordersBox),
      Hive.openBox<String>(StorageKeys.missionsBox),
      Hive.openBox<String>(StorageKeys.disputesBox),
      Hive.openBox<String>(StorageKeys.notificationsBox),
      Hive.openBox<String>(StorageKeys.messagesBox),
      Hive.openBox<String>(StorageKeys.favoritesBox),
      Hive.openBox<String>(StorageKeys.sessionBox),
      Hive.openBox<String>(StorageKeys.settingsBox),
      Hive.openBox<String>('categories_box'),
      Hive.openBox<String>('conversations_box'),
      Hive.openBox<String>('payments_box'),
    ]);

    _initialized = true;
  }

  /// Supprime TOUTES les données locales. Utile pour un bouton
  /// "Réinitialiser les données de démonstration" dans les réglages,
  /// ou pour les tests.
  static Future<void> clearAll() async {
    for (final boxName in [
      StorageKeys.usersBox,
      StorageKeys.productsBox,
      StorageKeys.sellerRequestsBox,
      StorageKeys.ordersBox,
      StorageKeys.missionsBox,
      StorageKeys.disputesBox,
      StorageKeys.notificationsBox,
      StorageKeys.messagesBox,
      StorageKeys.favoritesBox,
      StorageKeys.sessionBox,
      'categories_box',
      'conversations_box',
      'payments_box',
    ]) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<String>(boxName).clear();
      }
    }
  }
}

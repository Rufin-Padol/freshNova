import 'package:hive_ce_flutter/hive_flutter.dart';

/// Petit utilitaire qui détermine si les données de démonstration ont
/// déjà été insérées, pour ne jamais les dupliquer à chaque démarrage
/// de l'application.
///
/// Utilise une box Hive dédiée et minimaliste plutôt que de vérifier
/// "users_box est-elle vide ?", car cette dernière approche poserait
/// problème si l'utilisateur supprime manuellement tous ses comptes :
/// le seed se relancerait alors qu'on ne le souhaite pas forcément.
class DemoSeedCheck {
  DemoSeedCheck._();

  static const String _boxName = 'app_meta_box';
  static const String _seedKey = 'demo_data_seeded';

  static Future<bool> isAlreadySeeded() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    final box = Hive.box<String>(_boxName);
    return box.get(_seedKey) == 'true';
  }

  static Future<void> markAsSeeded() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    final box = Hive.box<String>(_boxName);
    await box.put(_seedKey, 'true');
  }

  /// Permet de forcer une réinitialisation complète des données de
  /// démonstration (utilisé par le bouton "Réinitialiser" dans les
  /// réglages, voir script des écrans de profil).
  static Future<void> resetSeedFlag() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    final box = Hive.box<String>(_boxName);
    await box.delete(_seedKey);
  }
}

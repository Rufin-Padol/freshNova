/// Mode de fonctionnement des sources de données de l'application.
///
/// [local]  : toutes les données (produits, commandes, utilisateurs...)
///            sont lues et écrites dans la base locale Hive. C'est le
///            mode actuel, utilisé pendant le développement et les
///            démonstrations, y compris sans connexion internet.
///
/// [api]    : toutes les données passent par l'API Spring Boot via Dio.
///            À activer uniquement lorsque le backend est déployé et
///            joignable à l'adresse définie dans [AppConfig.apiBaseUrl].
enum DataMode { local, api }

/// Point de configuration UNIQUE de l'application.
///
/// Pour basculer toute l'application du mode local vers l'API, il suffit
/// de changer [dataMode] ci-dessous et de renseigner [apiBaseUrl].
/// Aucun autre fichier du projet n'a besoin d'être modifié : tous les
/// repositories utilisent ce flag pour décider quelle implémentation
/// (locale ou API) injecter (voir lib/data/repositories).
class AppConfig {
  AppConfig._();

  // ──────────────────────────────────────────────────────────────────
  // ⚙️  POINT DE BASCULE PRINCIPAL
  // Changez UNIQUEMENT cette ligne pour passer en mode API plus tard.
  // ──────────────────────────────────────────────────────────────────
  static const DataMode dataMode = DataMode.local;

  /// Adresse de base de l'API Spring Boot. Ignorée tant que [dataMode]
  /// vaut [DataMode.local]. À renseigner avec l'URL réelle du serveur
  /// (ex: 'https://api.afrideal.cm' ou 'http://10.0.2.2:8080' pour un
  /// backend local testé depuis l'émulateur Android).
  static const String apiBaseUrl = 'http://localhost:8080/api/v1';

  /// Délai maximal d'attente avant qu'une requête API soit considérée
  /// en échec. Volontairement court pour ne jamais bloquer l'utilisateur
  /// longtemps sur un réseau lent (objectif 2G).
  static const Duration apiTimeout = Duration(seconds: 12);

  /// Raccourci pratique utilisé dans tout le code :
  /// `if (AppConfig.isLocal) { ... } else { ... }`
  static bool get isLocal => dataMode == DataMode.local;
  static bool get isApi => dataMode == DataMode.api;

  /// Active ou désactive les logs de debug dans la console.
  static const bool enableDebugLogs = true;

  /// Nom de l'application affiché dans l'UI.
  static const String appName = 'AfriDeal';
}

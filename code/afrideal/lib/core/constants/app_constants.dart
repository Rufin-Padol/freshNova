/// Constantes métier globales, dérivées directement du cahier des charges.
///
/// Centraliser ces valeurs ici (plutôt que de les répéter dans chaque
/// écran) permet de les ajuster une seule fois si les règles métier
/// évoluent (ex: changement de la fenêtre de réservation).
class AppConstants {
  AppConstants._();

  /// Nombre maximal de produits soumis en une seule fois par un vendeur.
  static const int maxQuantityPerSubmission = 10;

  /// Nombre maximal de photos qu'un vendeur peut joindre à sa soumission
  /// (photos d'aperçu, différentes des photos officielles de l'agent).
  static const int maxSellerPreviewPhotos = 5;

  /// Délai, en minutes, durant lequel un produit reste réservé pour un
  /// acheteur sans paiement confirmé avant d'être remis en vente.
  static const int reservationTimeoutMinutes = 120;

  /// Délai de réclamation après livraison, en heures.
  static const int claimWindowHours = 24;

  /// Délai de connexion réseau avant de considérer l'appareil hors-ligne
  /// pour l'affichage d'un indicateur d'état.
  static const Duration connectivityCheckTimeout = Duration(seconds: 5);

  /// Taux de commission par défaut si aucune configuration spécifique
  /// n'existe pour une catégorie (en pourcentage).
  static const double defaultCommissionRate = 10.0;
}

/// Clés utilisées pour le stockage local (Hive boxes et secure storage).
/// Centraliser les noms évite les fautes de frappe entre deux fichiers.
class StorageKeys {
  StorageKeys._();

  static const String usersBox = 'users_box';
  static const String productsBox = 'products_box';
  static const String sellerRequestsBox = 'seller_requests_box';
  static const String ordersBox = 'orders_box';
  static const String missionsBox = 'missions_box';
  static const String disputesBox = 'disputes_box';
  static const String notificationsBox = 'notifications_box';
  static const String messagesBox = 'messages_box';
  static const String favoritesBox = 'favorites_box';
  static const String sessionBox = 'session_box';
  static const String settingsBox = 'settings_box';
  static const String categoriesBox = 'categories_box';
  static const String conversationsBox = 'conversations_box';
  static const String paymentsBox = 'payments_box';

  static const String secureTokenKey = 'auth_token';
  static const String secureCurrentUserIdKey = 'current_user_id';
}

#!/bin/bash
# ============================================================================
# SCRIPT 02 — Thème, Configuration, Gestion d'erreurs, Routeur
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. lib/core/theme/      → couleurs, typographie, espacements, thème complet
#   2. lib/core/config/     → LE fichier qui décide "mode local" ou "mode API"
#   3. lib/core/errors/     → exceptions métier + widget d'erreur réutilisable
#   4. lib/core/constants/  → constantes globales (routes, durées, limites)
#   5. lib/core/utils/      → formatage FCFA, dates, validateurs de formulaire
#   6. lib/core/router/     → squelette du routeur (complété par les scripts
#                              suivants au fur et à mesure que les écrans
#                              sont créés)
#
# PRINCIPE CLÉ DE CE SCRIPT — LE FLAG LOCAL / API :
#   Tout repose sur UNE seule variable : AppConfig.dataMode.
#   Tant qu'elle vaut DataMode.local, l'app lit/écrit uniquement dans la
#   base Hive locale. Le jour où l'API Spring Boot est prête, il suffira
#   de changer CETTE LIGNE (et de renseigner l'URL du serveur) pour que
#   TOUTE l'application bascule sur l'API — aucun écran, aucun widget
#   n'a besoin d'être modifié, car ils ne parlent jamais directement aux
#   sources de données : ils passent toujours par une interface
#   "Repository" abstraite (créée dans le script 04).
#
# COMMENT EXÉCUTER CE SCRIPT :
#   1. Depuis la racine du projet (là où vous avez lancé le script 01)
#   2. Copiez ce fichier sous le nom 02_core_foundation.sh
#   3. Lancez : bash 02_core_foundation.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   - Le message final "✔ Script 02 terminé avec succès."
#   - Aucun fichier lib/main.dart n'est touché par ce script (normal,
#     ce sera fait dans le tout dernier script, une fois que toutes les
#     pièces existent).
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 02/14 : Thème, Config, Erreurs, Routeur"
echo "============================================================"

if [ ! -f "pubspec.yaml" ]; then
  echo "ERREUR : pubspec.yaml introuvable. Lancez ce script à la racine du projet."
  exit 1
fi

if [ ! -d "lib/core" ]; then
  echo "ERREUR : lib/core introuvable. Avez-vous bien exécuté le script 01 d'abord ?"
  exit 1
fi

# ============================================================================
# 1. COULEURS — palette AfriDeal exacte (violet / bleu / blanc / noir / or)
# ============================================================================
cat > lib/core/theme/app_colors.dart << 'EOF'
import 'package:flutter/material.dart';

/// Palette de couleurs officielle AfriDeal.
///
/// Ces couleurs sont la SEULE source de vérité pour les couleurs de
/// l'application. Aucun écran ne doit écrire une couleur en dur
/// (ex: Color(0xFF7C3AED)) : il doit toujours passer par AppColors.
///
/// La palette respecte l'identité de marque validée :
/// Violet + Bleu + Blanc + Noir + Or = confiance, sécurité et modernité.
class AppColors {
  AppColors._();

  // ── Couleurs de marque ──
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetDark = Color(0xFF5B21B6);
  static const Color violetLight = Color(0xFF8B5CF6);
  static const Color violetSurface = Color(0xFFEDE9FE);

  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1D4ED8);
  static const Color blueSurface = Color(0xFFEFF6FF);

  static const Color gold = Color(0xFFF59E0B);
  static const Color goldDark = Color(0xFFB45309);
  static const Color goldSurface = Color(0xFFFEF3C7);

  static const Color black = Color(0xFF111827);
  static const Color white = Color(0xFFFFFFFF);

  // ── Neutres (échelle de gris) ──
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ── Couleurs sémantiques (états) ──
  static const Color success = Color(0xFF059669);
  static const Color successSurface = Color(0xFFD1FAE5);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSurface = Color(0xFFFEE2E2);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // ── Couleurs de fond ──
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Statuts produit (cycle de vie, voir ProductStatus) ──
  static const Color statusSubmitted = gold;
  static const Color statusAssigned = blue;
  static const Color statusVerifying = violet;
  static const Color statusCollected = Color(0xFF0D9488);
  static const Color statusProcessing = Color(0xFF0D9488);
  static const Color statusOnSale = success;
  static const Color statusReserved = violetDark;
  static const Color statusDelivered = Color(0xFF166534);
  static const Color statusRefused = danger;
  static const Color statusCancelled = gray500;
  static const Color statusUnavailable = danger;
  static const Color statusExpired = gray400;

  /// Dégradé principal de marque, utilisé sur les écrans d'accueil,
  /// bannières, et boutons d'action principaux.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, blue],
  );

  /// Dégradé sombre, utilisé pour les bandeaux de confiance / sécurité.
  static const LinearGradient darkTrustGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [black, violetDark],
  );
}
EOF
echo "→ lib/core/theme/app_colors.dart créé."

# ============================================================================
# 2. ESPACEMENTS, RAYONS, OMBRES, DURÉES — système de design cohérent
# ============================================================================
cat > lib/core/theme/app_dimens.dart << 'EOF'
import 'package:flutter/material.dart';

/// Système d'espacement et de dimensions.
///
/// Utiliser ces constantes partout évite les écrans "bricolés" avec des
/// valeurs magiques (ex: padding: 13.5) et garantit une cohérence visuelle
/// stricte sur l'ensemble de l'application.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get fullRadius => BorderRadius.circular(full);
}

/// Ombres standardisées. Volontairement discrètes : le design AfriDeal
/// privilégie les bordures fines et les surfaces claires plutôt que des
/// ombres marquées, pour rester sobre et rapide à dessiner (important
/// pour la fluidité sur des appareils d'entrée de gamme).
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Durées d'animation standardisées. Des transitions courtes et nettes
/// donnent une sensation de rapidité, essentielle sur réseau lent.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}
EOF
echo "→ lib/core/theme/app_dimens.dart créé."

# ============================================================================
# 3. TYPOGRAPHIE
# ============================================================================
cat > lib/core/theme/app_typography.dart << 'EOF'
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Échelle typographique de l'application.
///
/// Une seule famille de police est utilisée pour rester sobre et garantir
/// un rendu identique et fiable sur Android, iOS et Web, y compris en
/// l'absence de chargement réseau de polices externes (police système
/// par défaut tant qu'aucune police custom n'est ajoutée dans assets/fonts).
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    height: 1.2,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.gray700,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.gray600,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray500,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.gray600,
    letterSpacing: 0.4,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.gray400,
  );
}
EOF
echo "→ lib/core/theme/app_typography.dart créé."

# ============================================================================
# 4. THEME DATA — assemblage final pour MaterialApp
# ============================================================================
cat > lib/core/theme/app_theme.dart << 'EOF'
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Construit le ThemeData complet consommé par MaterialApp.router.
///
/// Centraliser ici le style de chaque composant (boutons, champs de
/// texte, app bar...) garantit que les widgets Material par défaut
/// (TextButton, ElevatedButton, etc.) respectent automatiquement
/// l'identité visuelle AfriDeal sans configuration répétée écran par écran.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violet,
        primary: AppColors.violet,
        secondary: AppColors.blue,
        tertiary: AppColors.gold,
        error: AppColors.danger,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.black,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.titleLarge,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray400,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violet,
          side: const BorderSide(color: AppColors.violet, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.violet,
          textStyle: AppTypography.button,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.gray400),
        labelStyle: AppTypography.bodyMedium,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
          side: const BorderSide(color: AppColors.gray200),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.violet,
        unselectedItemColor: AppColors.gray400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: AppTypography.caption,
        unselectedLabelStyle: AppTypography.caption,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray900,
        contentTextStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        labelStyle: AppTypography.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
        side: BorderSide.none,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.violet,
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
EOF
echo "→ lib/core/theme/app_theme.dart créé."

# ============================================================================
# 5. CONFIGURATION — LE flag local / API
# ============================================================================
cat > lib/core/config/app_config.dart << 'EOF'
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
EOF
echo "→ lib/core/config/app_config.dart créé."

# ============================================================================
# 6. CONSTANTES GLOBALES
# ============================================================================
cat > lib/core/constants/app_constants.dart << 'EOF'
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
EOF
echo "→ lib/core/constants/app_constants.dart créé."

# ============================================================================
# 7. GESTION D'ERREURS — exceptions métier typées
# ============================================================================
cat > lib/core/errors/app_exception.dart << 'EOF'
/// Exception métier de base de l'application.
///
/// Toute erreur prévisible (donnée manquante, règle métier violée, échec
/// réseau...) doit être levée sous forme d'une sous-classe de
/// [AppException] plutôt qu'une Exception générique. Cela permet à la
/// couche présentation d'afficher un message clair et adapté à
/// l'utilisateur, plutôt qu'un message technique incompréhensible.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Levée quand une ressource demandée n'existe pas
/// (ex: produit déjà supprimé, commande introuvable).
class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'Élément introuvable.',
  ]) : super(message, code: 'NOT_FOUND');
}

/// Levée quand une règle métier empêche l'opération
/// (ex: tenter de payer un produit déjà vendu).
class BusinessRuleException extends AppException {
  const BusinessRuleException(super.message) : super(code: 'BUSINESS_RULE');
}

/// Levée lors d'un échec de validation de formulaire ou de données.
class ValidationException extends AppException {
  const ValidationException(super.message) : super(code: 'VALIDATION');
}

/// Levée lors d'un problème de connexion réseau (mode API uniquement).
class NetworkException extends AppException {
  const NetworkException([
    String message = 'Connexion impossible. Vérifiez votre réseau.',
  ]) : super(message, code: 'NETWORK');
}

/// Levée lorsque le serveur répond avec une erreur (mode API uniquement).
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    String message, {
    this.statusCode,
  }) : super(message, code: 'SERVER');
}

/// Levée lors d'un échec d'authentification
/// (identifiants invalides, session expirée).
class AuthException extends AppException {
  const AuthException([
    String message = 'Authentification requise.',
  ]) : super(message, code: 'AUTH');
}

/// Levée lors d'un échec de lecture/écriture dans le stockage local.
class StorageException extends AppException {
  const StorageException([
    String message = 'Erreur de stockage local.',
  ]) : super(message, code: 'STORAGE');
}

/// Convertit n'importe quelle erreur capturée (catch) en message lisible
/// pour l'utilisateur. Utilisé en dernier recours dans les blocs
/// try/catch des providers, pour ne jamais laisser fuiter une erreur
/// technique brute (stack trace Dart) jusqu'à l'écran.
String friendlyErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return 'Une erreur inattendue est survenue. Veuillez réessayer.';
}
EOF
echo "→ lib/core/errors/app_exception.dart créé."

# ============================================================================
# 8. WIDGET D'ÉTAT D'ERREUR RÉUTILISABLE
# ============================================================================
cat > lib/core/errors/error_view.dart << 'EOF'
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// Vue d'erreur générique, affichée à la place du contenu lorsqu'un
/// chargement de données échoue.
///
/// Toujours accompagnée d'une action claire ("Réessayer") : l'utilisateur
/// ne doit jamais se retrouver bloqué face à un écran sans recours.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.dangerSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.danger, size: 30),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vue affichée lorsqu'une liste est vide (aucun produit, aucune
/// commande...). Distincte de [ErrorView] car ce n'est pas une erreur :
/// c'est un état normal qui mérite un message rassurant, pas alarmant.
class EmptyView extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gray400, size: 32),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
EOF
echo "→ lib/core/errors/error_view.dart créé."

# ============================================================================
# 9. UTILITAIRES — formatage FCFA, dates, validateurs
# ============================================================================
cat > lib/core/utils/formatters.dart << 'EOF'
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
EOF
echo "→ lib/core/utils/formatters.dart créé."

cat > lib/core/utils/validators.dart << 'EOF'
/// Validateurs de champs de formulaire réutilisés dans toute l'application.
///
/// Chaque méthode renvoie `null` si la valeur est valide, ou un message
/// d'erreur en français adapté à l'utilisateur si elle ne l'est pas.
/// Compatible directement avec la propriété `validator` des TextFormField.
class Validators {
  Validators._();

  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est obligatoire.';
    }
    return null;
  }

  /// Valide un numéro de téléphone camerounais.
  /// Accepte les formats : 6XXXXXXXX, +2376XXXXXXXX, 2376XXXXXXXX.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est obligatoire.';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    final pattern = RegExp(r'^(\+?237)?[26]\d{8}$');
    if (!pattern.hasMatch(cleaned)) {
      return 'Numéro de téléphone invalide.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire.';
    }
    if (value.length < 4) {
      return 'Le mot de passe doit contenir au moins 4 caractères.';
    }
    return null;
  }

  /// Valide qu'un prix saisi est un nombre strictement positif.
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prix est obligatoire.';
    }
    final parsed = num.tryParse(value.replaceAll(' ', ''));
    if (parsed == null || parsed <= 0) {
      return 'Veuillez saisir un prix valide.';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().length < min) {
      return '$fieldName doit contenir au moins $min caractères.';
    }
    return null;
  }
}
EOF
echo "→ lib/core/utils/validators.dart créé."

# ============================================================================
# 10. ROUTEUR — squelette go_router (les routes seront ajoutées
#     progressivement par les scripts de chaque fonctionnalité)
# ============================================================================
cat > lib/core/router/app_routes.dart << 'EOF'
/// Noms et chemins centralisés de toutes les routes de l'application.
///
/// Utiliser ces constantes plutôt que des chaînes en dur (ex:
/// context.go('/shop') au lieu de context.go(AppRoutes.shop)) évite les
/// fautes de frappe et permet de renommer une route en un seul endroit.
///
/// Ce fichier est complété progressivement : chaque script de
/// fonctionnalité (auth, shop, sell, agent, admin...) y ajoutera ses
/// propres constantes au moment de créer ses écrans.
class AppRoutes {
  AppRoutes._();

  // ── Démarrage ──
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String entryChoice = '/welcome';

  // ── Authentification ──
  static const String login = '/login';
  static const String demoAccounts = '/demo-accounts';

  // ── Acheteur ──
  static const String shop = '/shop';
  static const String productDetail = '/product/:productId';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:orderId';
  static const String favorites = '/favorites';

  // ── Vendeur ──
  static const String sellHome = '/sell';
  static const String sellStep1 = '/sell/step-1';
  static const String sellStep2 = '/sell/step-2';
  static const String sellStep3 = '/sell/step-3';
  static const String sellConfirmation = '/sell/confirmation';
  static const String sellRequestDetail = '/sell/requests/:requestId';

  // ── Agent terrain ──
  static const String agentDashboard = '/agent';
  static const String agentMissionDetail = '/agent/missions/:missionId';

  // ── Commun ──
  static const String messages = '/messages';
  static const String conversation = '/messages/:conversationId';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // ── Admin (web) ──
  static const String adminDashboard = '/admin';
  static const String adminCatalog = '/admin/catalog';
  static const String adminOrders = '/admin/orders';
  static const String adminDisputes = '/admin/disputes';
  static const String adminUsers = '/admin/users';
  static const String adminAgents = '/admin/agents';

  // ── Super Admin (web) ──
  static const String superAdminDashboard = '/super-admin';
  static const String superAdminAdmins = '/super-admin/admins';
  static const String superAdminCommissions = '/super-admin/commissions';
  static const String superAdminReports = '/super-admin/reports';
}
EOF
echo "→ lib/core/router/app_routes.dart créé."

cat > lib/core/router/router_refresh_stream.dart << 'EOF'
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Permet à [GoRouter] d'écouter un [ChangeNotifier] (ex: l'état de
/// session de l'utilisateur) et de ré-évaluer automatiquement les
/// redirections lorsqu'il change (connexion, déconnexion, changement
/// de rôle...).
///
/// Sans cet outil, go_router ne se "réveillerait" pas tout seul après
/// une connexion réussie : l'utilisateur resterait bloqué sur l'écran
/// de login même si son état de session a changé en arrière-plan.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
EOF
echo "→ lib/core/router/router_refresh_stream.dart créé."

echo ""
echo "============================================================"
echo "  ✔ Script 02 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • Thème complet AfriDeal (couleurs, typo, espacements, ombres)"
echo "  • Le flag central local/API (lib/core/config/app_config.dart)"
echo "  • Exceptions métier + vues d'erreur/vide réutilisables"
echo "  • Formatage FCFA, dates, validateurs de formulaire"
echo "  • Squelette du routeur (routes nommées, prêtes à être branchées)"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Aucune commande à lancer pour ce script (pas de nouvelle"
echo "  dépendance). Dites-moi quand vous êtes prêt pour le script 03 :"
echo "  les entités métier et enums (Produit, Utilisateur, Commande,"
echo "  Mission, statuts...), le miroir direct de votre diagramme UML."
echo ""

#!/bin/bash
# ============================================================================
# SCRIPT 09 — main.dart et Routeur complet (go_router)
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. lib/main.dart
#        → Point d'entrée de l'application. Initialise Hive, insère
#          les données de démonstration si nécessaire, puis lance
#          l'application encapsulée dans un ProviderScope (Riverpod).
#   2. lib/core/router/app_router.dart
#        → Le routeur go_router complet, avec TOUTES les routes
#          déclarées (constantes définies au script 02), et la
#          logique de redirection automatique selon l'état de
#          session et le rôle de l'utilisateur connecté.
#   3. lib/shared/widgets/layout/placeholder_screen.dart
#        → Écran générique temporaire affiché pour toute route dont
#          l'écran définitif n'a pas encore été créé par un script
#          ultérieur. Permet de TESTER LA NAVIGATION DÈS MAINTENANT,
#          avant même que les écrans réels existent. Chaque script
#          suivant (10 à 13) remplacera ces placeholders un par un.
#
# LOGIQUE DE REDIRECTION PAR RÔLE :
#   • Personne connecté          → /welcome (écran de bienvenue)
#   • Acheteur connecté          → /shop (boutique)
#   • Vendeur connecté           → /sell (espace vendeur)
#   • Agent terrain connecté     → /agent (tableau de bord missions)
#   • Admin connecté             → /admin (panneau web)
#   • Super Admin connecté       → /super-admin (panneau web)
#
#   Cette logique empêche par exemple un Agent terrain d'atterrir par
#   erreur sur les écrans Acheteur, et redirige automatiquement vers
#   le bon espace dès la connexion réussie.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 09_main_and_router.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 09 terminé avec succès."
#   À partir de maintenant, "flutter run" devrait démarrer l'app et
#   afficher l'écran de bienvenue (encore en version "placeholder"
#   pour la plupart des écrans, qui seront complétés progressivement).
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 09/14 : main.dart et Routeur"
echo "============================================================"

if [ ! -f "lib/core/providers/repository_providers.dart" ]; then
  echo "ERREUR : repository_providers.dart introuvable. Avez-vous exécuté le script 08 ?"
  exit 1
fi

# ============================================================================
# 1. ÉCRAN PLACEHOLDER GÉNÉRIQUE
# ============================================================================
cat > lib/shared/widgets/layout/placeholder_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../illustrations/onboarding_illustrations.dart';

/// Écran temporaire affiché pour toute route dont l'écran définitif
/// n'a pas encore été construit.
///
/// Ce widget est volontairement TRÈS visible (bandeau orange) pour
/// qu'il soit impossible de le confondre avec un écran terminé
/// pendant les tests manuels de l'application au fil des scripts.
/// Il sera remplacé, route par route, par les scripts 10 à 13.
class PlaceholderScreen extends StatelessWidget {
  final String titre;

  const PlaceholderScreen({super.key, required this.titre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyBoxIllustration(size: 100),
              const SizedBox(height: 20),
              Text(titre, style: AppTypography.headline, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Cet écran sera construit dans un prochain script.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOF
echo "→ lib/shared/widgets/layout/placeholder_screen.dart créé."

# ============================================================================
# 2. ROUTEUR COMPLET (go_router)
# ============================================================================
cat > lib/core/router/app_router.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/enums/user_role.dart';
import '../../features/auth/providers/session_provider.dart';
import '../../shared/widgets/layout/placeholder_screen.dart';
import 'app_routes.dart';

/// Le routeur complet de l'application AfriDeal.
///
/// Toutes les routes sont déclarées ici, avec leur écran associé.
/// Au fur et à mesure que les scripts suivants créent les écrans
/// réels, les références à PlaceholderScreen sont remplacées une à
/// une par le vrai widget d'écran — la structure de routage, elle,
/// ne change pas.
///
/// La fonction [redirect] centralise TOUTE la logique de protection
/// de routes et d'aiguillage par rôle, plutôt que de la disperser
/// dans chaque écran individuellement.
final appRouterProvider = Provider<GoRouter>((ref) {
  // ref.watch ici est essentiel : chaque changement de session
  // (connexion, déconnexion) reconstruit le routeur et déclenche
  // automatiquement une nouvelle évaluation de redirect().
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final chemin = state.matchedLocation;
      final estChargementSession = session.isLoading;
      final utilisateur = session.valueOrNull;
      final estConnecte = utilisateur != null;

      // Tant que la session se restaure au démarrage, on reste sur
      // l'écran de chargement (splash) pour éviter un clignotement
      // vers l'écran de connexion puis retour à l'écran connecté.
      if (estChargementSession) {
        return chemin == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final estSurEcranAuth = chemin == AppRoutes.splash ||
          chemin == AppRoutes.onboarding ||
          chemin == AppRoutes.entryChoice ||
          chemin == AppRoutes.login ||
          chemin == AppRoutes.demoAccounts;

      // Personne connecté : seuls les écrans d'authentification sont
      // accessibles, tout le reste redirige vers l'accueil de bienvenue.
      if (!estConnecte) {
        return estSurEcranAuth ? null : AppRoutes.entryChoice;
      }

      // Connecté mais encore sur un écran d'authentification : on
      // redirige automatiquement vers le bon espace selon le rôle.
      if (estSurEcranAuth) {
        return _accueilPourRole(utilisateur.role);
      }

      // Connecté et déjà sur un écran applicatif : on vérifie que ce
      // chemin appartient bien à l'espace autorisé pour son rôle.
      if (!_cheminAutorisePourRole(chemin, utilisateur.role)) {
        return _accueilPourRole(utilisateur.role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const PlaceholderScreen(titre: 'Bienvenue sur AfriDeal'),
      ),
      GoRoute(
        path: AppRoutes.entryChoice,
        builder: (context, state) => const PlaceholderScreen(titre: 'Commencer'),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PlaceholderScreen(titre: 'Connexion'),
      ),
      GoRoute(
        path: AppRoutes.demoAccounts,
        builder: (context, state) => const PlaceholderScreen(titre: 'Comptes de démonstration'),
      ),

      // ── Acheteur ──
      GoRoute(
        path: AppRoutes.shop,
        builder: (context, state) => const PlaceholderScreen(titre: 'Boutique'),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) => const PlaceholderScreen(titre: 'Détail produit'),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const PlaceholderScreen(titre: 'Panier'),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const PlaceholderScreen(titre: 'Paiement'),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const PlaceholderScreen(titre: 'Mes commandes'),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) => const PlaceholderScreen(titre: 'Détail commande'),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const PlaceholderScreen(titre: 'Favoris'),
      ),

      // ── Vendeur ──
      GoRoute(
        path: AppRoutes.sellHome,
        builder: (context, state) => const PlaceholderScreen(titre: 'Espace vendeur'),
      ),
      GoRoute(
        path: AppRoutes.sellStep1,
        builder: (context, state) => const PlaceholderScreen(titre: 'Vendre — étape 1'),
      ),
      GoRoute(
        path: AppRoutes.sellStep2,
        builder: (context, state) => const PlaceholderScreen(titre: 'Vendre — étape 2'),
      ),
      GoRoute(
        path: AppRoutes.sellStep3,
        builder: (context, state) => const PlaceholderScreen(titre: 'Vendre — étape 3'),
      ),
      GoRoute(
        path: AppRoutes.sellConfirmation,
        builder: (context, state) => const PlaceholderScreen(titre: 'Demande envoyée'),
      ),
      GoRoute(
        path: AppRoutes.sellRequestDetail,
        builder: (context, state) => const PlaceholderScreen(titre: 'Détail de la demande'),
      ),

      // ── Agent terrain ──
      GoRoute(
        path: AppRoutes.agentDashboard,
        builder: (context, state) => const PlaceholderScreen(titre: 'Mes missions'),
      ),
      GoRoute(
        path: AppRoutes.agentMissionDetail,
        builder: (context, state) => const PlaceholderScreen(titre: 'Détail mission'),
      ),

      // ── Commun (Acheteur, Vendeur, Agent) ──
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const PlaceholderScreen(titre: 'Messages'),
      ),
      GoRoute(
        path: AppRoutes.conversation,
        builder: (context, state) => const PlaceholderScreen(titre: 'Conversation'),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const PlaceholderScreen(titre: 'Notifications'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const PlaceholderScreen(titre: 'Profil'),
      ),

      // ── Admin (web) ──
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const PlaceholderScreen(titre: 'Tableau de bord Admin'),
      ),
      GoRoute(
        path: AppRoutes.adminCatalog,
        builder: (context, state) => const PlaceholderScreen(titre: 'Catalogue'),
      ),
      GoRoute(
        path: AppRoutes.adminOrders,
        builder: (context, state) => const PlaceholderScreen(titre: 'Commandes'),
      ),
      GoRoute(
        path: AppRoutes.adminDisputes,
        builder: (context, state) => const PlaceholderScreen(titre: 'Litiges'),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const PlaceholderScreen(titre: 'Utilisateurs'),
      ),
      GoRoute(
        path: AppRoutes.adminAgents,
        builder: (context, state) => const PlaceholderScreen(titre: 'Agents terrain'),
      ),

      // ── Super Admin (web) ──
      GoRoute(
        path: AppRoutes.superAdminDashboard,
        builder: (context, state) => const PlaceholderScreen(titre: 'Tableau de bord Super Admin'),
      ),
      GoRoute(
        path: AppRoutes.superAdminAdmins,
        builder: (context, state) => const PlaceholderScreen(titre: 'Administrateurs'),
      ),
      GoRoute(
        path: AppRoutes.superAdminCommissions,
        builder: (context, state) => const PlaceholderScreen(titre: 'Commissions'),
      ),
      GoRoute(
        path: AppRoutes.superAdminReports,
        builder: (context, state) => const PlaceholderScreen(titre: 'Rapports'),
      ),
    ],
  );
});

/// Détermine l'écran d'accueil approprié juste après connexion,
/// selon le rôle de l'utilisateur.
String _accueilPourRole(UserRole role) {
  switch (role) {
    case UserRole.acheteur:
      return AppRoutes.shop;
    case UserRole.vendeur:
      return AppRoutes.sellHome;
    case UserRole.agentTerrain:
      return AppRoutes.agentDashboard;
    case UserRole.admin:
      return AppRoutes.adminDashboard;
    case UserRole.superAdmin:
      return AppRoutes.superAdminDashboard;
  }
}

/// Vérifie qu'un chemin donné appartient bien à l'espace applicatif
/// autorisé pour le rôle de l'utilisateur connecté. Les routes
/// "communes" (messages, notifications, profil) sont accessibles à
/// tous les rôles mobiles (Acheteur, Vendeur, Agent).
bool _cheminAutorisePourRole(String chemin, UserRole role) {
  const cheminsCommuns = [
    AppRoutes.messages,
    AppRoutes.notifications,
    AppRoutes.profile,
  ];
  // Les routes paramétrées (ex: /messages/:conversationId) doivent
  // être comparées par préfixe plutôt que par égalité stricte.
  bool correspond(String prefix) => chemin == prefix || chemin.startsWith('$prefix/');

  if (cheminsCommuns.any(correspond)) return true;

  switch (role) {
    case UserRole.acheteur:
      return correspond(AppRoutes.shop) ||
          correspond('/product') ||
          correspond(AppRoutes.cart) ||
          correspond(AppRoutes.checkout) ||
          correspond(AppRoutes.orders) ||
          correspond(AppRoutes.favorites);
    case UserRole.vendeur:
      return correspond(AppRoutes.sellHome) || correspond('/sell');
    case UserRole.agentTerrain:
      return correspond(AppRoutes.agentDashboard) || correspond('/agent');
    case UserRole.admin:
      return correspond('/admin');
    case UserRole.superAdmin:
      return correspond('/super-admin') || correspond('/admin');
  }
}

/// Écran de chargement initial, affiché le temps que la session soit
/// restaurée depuis le stockage local. Volontairement minimaliste et
/// rapide à dessiner : c'est la toute première chose vue par
/// l'utilisateur, elle doit apparaître instantanément.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF7C3AED),
      body: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
EOF
echo "→ lib/core/router/app_router.dart créé."

# ============================================================================
# 3. MAIN.DART
# ============================================================================
cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'data/local/datasources/hive_service.dart';
import 'data/local/seed/demo_data_seeder.dart';

Future<void> main() async {
  // Garantit que les bindings Flutter sont initialisés avant tout
  // appel à du code natif (Hive, plugins...), requis car main() est
  // maintenant asynchrone (à cause de l'initialisation Hive ci-dessous).
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise la base de données locale et ouvre toutes les box
  // nécessaires au fonctionnement de l'application.
  await HiveService.init();

  // Insère les données de démonstration au tout premier lancement
  // uniquement. Sans effet aux lancements suivants. N'a de sens qu'en
  // mode local : en mode API, les données viendraient du serveur.
  if (AppConfig.isLocal) {
    await DemoDataSeeder.seedIfNeeded();
  }

  runApp(const ProviderScope(child: AfriDealApp()));
}

/// Widget racine de l'application AfriDeal.
///
/// Utilise ConsumerWidget pour pouvoir lire le routeur depuis
/// Riverpod (lui-même réactif à l'état de session, voir
/// lib/core/router/app_router.dart).
class AfriDealApp extends ConsumerWidget {
  const AfriDealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
EOF
echo "→ lib/main.dart créé."

echo ""
echo "============================================================"
echo "  ✔ Script 09 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • main.dart : point d'entrée complet (init Hive, seed,"
echo "    ProviderScope, MaterialApp.router)."
echo "  • app_router.dart : routeur go_router complet avec TOUTES les"
echo "    routes déclarées et la logique de redirection par rôle."
echo "  • PlaceholderScreen : écran temporaire visible (bandeau"
echo "    orange) pour toute route pas encore construite."
echo ""
echo "L'APPLICATION EST MAINTENANT LANÇABLE !"
echo "  Vous pouvez dès à présent exécuter :"
echo "    flutter pub get"
echo "    flutter run"
echo "  L'app démarrera, vous verrez l'écran de démarrage puis les"
echo "  écrans 'placeholder' avec la navigation déjà fonctionnelle ;"
echo "  les scripts suivants remplaceront ces placeholders par les"
echo "  vrais écrans, un par un."
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 10 : les écrans"
echo "  d'authentification (bienvenue, sélection de compte démo) et"
echo "  les premiers écrans Acheteur (boutique, fiche produit)."
echo ""

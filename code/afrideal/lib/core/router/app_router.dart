import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/enums/user_role.dart';
import '../router/app_transitions.dart';
import '../../shared/widgets/layout/role_shell_screen.dart';
import '../../features/auth/providers/session_provider.dart';
import '../../shared/widgets/layout/placeholder_screen.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/screens/entry_choice_screen.dart';
import '../../features/auth/presentation/screens/demo_accounts_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/product_detail/presentation/screens/product_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/sell/presentation/screens/sell_home_screen.dart';
import '../../features/sell/presentation/screens/sell_step1_screen.dart';
import '../../features/sell/presentation/screens/sell_step2_screen.dart';
import '../../features/sell/presentation/screens/sell_step3_screen.dart';
import '../../features/sell/presentation/screens/sell_confirmation_screen.dart';
import '../../features/sell/presentation/screens/sell_request_detail_screen.dart';
import '../../features/agent/presentation/screens/agent_dashboard_screen.dart';
import '../../features/agent/presentation/screens/agent_new_collecte_screen.dart';
import '../../features/messages/presentation/screens/messages_screen.dart';
import '../../features/messages/presentation/screens/conversation_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_shell_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_catalog_screen.dart';
import '../../features/admin/presentation/screens/admin_seller_requests_screen.dart';
import '../../features/admin/presentation/screens/admin_product_edit_screen.dart';
import '../../features/admin/presentation/screens/admin_disputes_screen.dart';
import '../../features/admin/presentation/screens/admin_agents_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_shell_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_admins_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_commissions_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/agent/presentation/screens/agent_mission_detail_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/cart_checkout/presentation/screens/checkout_screen.dart';
import '../../domain/entities/produit.dart';

/// Le routeur complet de l'application TrustNova.
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

      // Juste après le splash : un visiteur non connecté part
      // directement sur la boutique (principe "on regarde d'abord",
      // à la Alibaba — jamais de connexion forcée pour naviguer).
      if (chemin == AppRoutes.splash) {
        return estConnecte ? _accueilPourRole(utilisateur.role) : AppRoutes.shop;
      }

      final estSurEcranAuth = chemin == AppRoutes.onboarding ||
          chemin == AppRoutes.entryChoice ||
          chemin == AppRoutes.login ||
          chemin == AppRoutes.demoAccounts;

      // Boutique et fiches produit restent consultables sans compte :
      // la connexion n'est demandée qu'au moment d'une action précise
      // (favori, achat, vente, messages...), jamais pour simplement
      // regarder les produits.
      final estCheminPublic =
          estSurEcranAuth || chemin == AppRoutes.shop || chemin.startsWith('/product/');

      if (!estConnecte) {
        if (estCheminPublic) return null;
        // On mémorise le chemin visé dans "from" pour y revenir une
        // fois connecté, plutôt que d'atterrir systématiquement sur
        // l'accueil du rôle après connexion.
        final retour = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.demoAccounts}?from=$retour';
      }

      // Connecté mais encore sur un écran d'authentification : on
      // retourne au chemin d'origine si la connexion a été déclenchée
      // par une action précise (paramètre "from"), sinon accueil du rôle.
      if (estSurEcranAuth) {
        final from = state.uri.queryParameters['from'];
        if (from != null) {
          final destination = Uri.decodeComponent(from);
          if (_cheminAutorisePourRole(destination, utilisateur.role)) {
            return destination;
          }
        }
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
        builder: (context, state) => const PlaceholderScreen(titre: 'Bienvenue sur TrustNova'),
      ),
      GoRoute(
        path: AppRoutes.entryChoice,
        builder: (context, state) => const EntryChoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PlaceholderScreen(titre: 'Connexion'),
      ),
      GoRoute(
        path: AppRoutes.demoAccounts,
        builder: (context, state) => const DemoAccountsScreen(),
      ),

      // ── Acheteur ──
      GoRoute(
        path: AppRoutes.shop,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleShellScreen(child: ShopScreen()),
          transitionsBuilder: AppTransitions.fade,
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const PlaceholderScreen(titre: 'Panier'),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => CheckoutScreen(produit: state.extra as Produit),
      ),
      GoRoute(
        path: AppRoutes.orders,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleShellScreen(child: OrdersScreen()),
          transitionsBuilder: AppTransitions.fade,
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.favorites,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleShellScreen(child: FavoritesScreen()),
          transitionsBuilder: AppTransitions.fade,
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),

      // ── Vendeur ──
      GoRoute(
        path: AppRoutes.sellHome,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleShellScreen(child: SellHomeScreen()),
          transitionsBuilder: AppTransitions.fade,
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.sellStep1,
        builder: (context, state) => const SellStep1Screen(),
      ),
      GoRoute(
        path: AppRoutes.sellStep2,
        builder: (context, state) => const SellStep2Screen(),
      ),
      GoRoute(
        path: AppRoutes.sellStep3,
        builder: (context, state) => const SellStep3Screen(),
      ),
      GoRoute(
        path: AppRoutes.sellConfirmation,
        builder: (context, state) => const SellConfirmationScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellRequestDetail,
        builder: (context, state) {
          final requestId = state.pathParameters['requestId']!;
          return SellRequestDetailScreen(requestId: requestId);
        },
      ),

      // ── Agent terrain ──
      GoRoute(
        path: AppRoutes.agentDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleShellScreen(child: AgentDashboardScreen()),
          transitionsBuilder: AppTransitions.fade,
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.agentNewCollecte,
        builder: (context, state) => const AgentNewCollecteScreen(),
      ),
      GoRoute(
        path: AppRoutes.agentMissionDetail,
        builder: (context, state) {
          final missionId = state.pathParameters['missionId']!;
          return AgentMissionDetailScreen(missionId: missionId);
        },
      ),

      // ── Commun (Acheteur, Vendeur, Agent) ──
      GoRoute(
        path: AppRoutes.messages,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleShellScreen(child: MessagesScreen()),
          transitionsBuilder: AppTransitions.fade,
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.conversation,
        builder: (context, state) {
          final id = state.pathParameters['conversationId']!;
          return ConversationScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleShellScreen(child: NotificationsScreen()),
          transitionsBuilder: AppTransitions.fade,
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleShellScreen(child: ProfileScreen()),
          transitionsBuilder: AppTransitions.fade,
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),

      // ── Admin (web) ──
      // Toutes ces routes partagent la sidebar Admin (AdminShellScreen),
      // sauf l'édition produit qui est un flux plein écran avec son
      // propre bouton retour (même logique que checkout ou sell-step).
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) =>
            const AdminShellScreen(child: AdminDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminCatalog,
        builder: (context, state) =>
            const AdminShellScreen(child: AdminCatalogScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminSellerRequests,
        builder: (context, state) =>
            const AdminShellScreen(child: AdminSellerRequestsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminProductEdit,
        builder: (context, state) => AdminProductEditScreen(produit: state.extra as Produit),
      ),
      GoRoute(
        path: AppRoutes.adminOrders,
        builder: (context, state) =>
            const AdminShellScreen(child: AdminOrdersScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminDisputes,
        builder: (context, state) =>
            const AdminShellScreen(child: AdminDisputesScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) =>
            const AdminShellScreen(child: AdminUsersScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminAgents,
        builder: (context, state) =>
            const AdminShellScreen(child: AdminAgentsScreen()),
      ),

      // ── Super Admin (web) ──
      GoRoute(
        path: AppRoutes.superAdminDashboard,
        builder: (context, state) =>
            const SuperAdminShellScreen(child: SuperAdminDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.superAdminAdmins,
        builder: (context, state) =>
            const SuperAdminShellScreen(child: SuperAdminAdminsScreen()),
      ),
      GoRoute(
        path: AppRoutes.superAdminCommissions,
        builder: (context, state) =>
            const SuperAdminShellScreen(child: SuperAdminCommissionsScreen()),
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

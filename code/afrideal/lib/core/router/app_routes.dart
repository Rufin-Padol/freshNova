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
  static const String agentNewCollecte = '/agent/new-collecte';
  static const String agentMissionDetail = '/agent/missions/:missionId';

  // ── Commun ──
  static const String messages = '/messages';
  static const String conversation = '/messages/:conversationId';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // ── Admin (web) ──
  static const String adminDashboard = '/admin';
  static const String adminCatalog = '/admin/catalog';
  static const String adminProductEdit = '/admin/catalog/:productId/edit';
  static const String adminSellerRequests = '/admin/seller-requests';
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

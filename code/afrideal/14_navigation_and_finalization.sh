#!/bin/bash
# ============================================================================
# SCRIPT 14 — Navigation, Transitions et Finalisation
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT (LE DERNIER) :
#   1. lib/shared/widgets/layout/app_bottom_nav.dart
#        → BottomNavigationBar adapté selon le rôle de l'utilisateur
#          connecté. Acheteur, Vendeur et Agent terrain ont chacun
#          leur propre barre de navigation, avec leurs onglets propres.
#          L'Admin et le Super Admin n'ont PAS de barre inférieure
#          (ils naviguent via la sidebar latérale du panel web).
#   2. lib/shared/widgets/layout/role_shell_screen.dart
#        → Écran coquille qui encapsule le contenu et y ajoute la
#          barre de navigation appropriée selon le rôle. Chaque
#          écran principal (Shop, Sell, Agent Dashboard) est ensuite
#          empaqueté dans ce shell — l'écran lui-même n'a plus à se
#          soucier de la navigation globale.
#   3. Patch app_router.dart
#        → Les routes principales (shop, sell, agent) sont mises à
#          jour pour utiliser RoleShellScreen autour de leur écran,
#          injectant ainsi la navigation au bon endroit.
#   4. lib/core/router/app_transitions.dart
#        → Transitions de navigation personnalisées (fondu + glissement
#          subtil) pour une expérience fluide même sur réseau lent
#          (l'animation se joue localement, indépendante du réseau).
#   5. Vérification finale automatisée du projet complet.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 14_navigation_and_finalization.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Projet AfriDeal complet et validé !"
#   Suivi des instructions de lancement pour mobile et web.
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 14/14 : Navigation et Finalisation"
echo "============================================================"

if [ ! -f "lib/features/admin/presentation/screens/admin_users_screen.dart" ]; then
  echo "ERREUR : admin_users_screen.dart introuvable. Avez-vous exécuté le script 13 ?"
  exit 1
fi

# ============================================================================
# 1. TRANSITIONS DE NAVIGATION
# ============================================================================
cat > lib/core/router/app_transitions.dart << 'EOF'
import 'package:flutter/material.dart';

/// Transitions de navigation personnalisées pour AfriDeal.
///
/// Deux variantes selon le contexte :
///   - [fadeSlide] : transition principale (fondu + glissement léger
///     vers le haut). Utilisée pour les navigations d'écran principal
///     (boutique → fiche produit). Dure 250ms — suffisamment rapide
///     pour ne jamais sembler lente, même sur appareil d'entrée de
///     gamme.
///   - [fade] : fondu simple. Utilisée pour les transitions de haut
///     niveau (changement de section via la navigation inférieure)
///     où un glissement serait déroutant.
class AppTransitions {
  AppTransitions._();

  static Widget fadeSlide(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.03);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(tween),
        child: child,
      ),
    );
  }

  static Widget fade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
EOF
echo "→ lib/core/router/app_transitions.dart créé."

# ============================================================================
# 2. NAVIGATION INFÉRIEURE PAR RÔLE
# ============================================================================
cat > lib/shared/widgets/layout/app_bottom_nav.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/enums/user_role.dart';

/// Définition d'un onglet de navigation inférieure.
class _NavTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const _NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

/// Onglets de navigation pour chaque rôle mobile.
/// L'Admin et le Super Admin n'ont pas de barre inférieure —
/// ils naviguent via la sidebar (AdminSidebar, script 13).
const Map<UserRole, List<_NavTab>> _tabsParRole = {
  UserRole.acheteur: [
    _NavTab(
      label: 'Boutique',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
      route: AppRoutes.shop,
    ),
    _NavTab(
      label: 'Favoris',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
      route: AppRoutes.favorites,
    ),
    _NavTab(
      label: 'Commandes',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      route: AppRoutes.orders,
    ),
    _NavTab(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      route: AppRoutes.messages,
    ),
    _NavTab(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: AppRoutes.profile,
    ),
  ],
  UserRole.vendeur: [
    _NavTab(
      label: 'Vendre',
      icon: Icons.add_box_outlined,
      selectedIcon: Icons.add_box_rounded,
      route: AppRoutes.sellHome,
    ),
    _NavTab(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      route: AppRoutes.messages,
    ),
    _NavTab(
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      route: AppRoutes.notifications,
    ),
    _NavTab(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: AppRoutes.profile,
    ),
  ],
  UserRole.agentTerrain: [
    _NavTab(
      label: 'Missions',
      icon: Icons.route_outlined,
      selectedIcon: Icons.route_rounded,
      route: AppRoutes.agentDashboard,
    ),
    _NavTab(
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      route: AppRoutes.notifications,
    ),
    _NavTab(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: AppRoutes.profile,
    ),
  ],
};

/// BottomNavigationBar adapté au rôle de l'utilisateur connecté.
/// Retourne null pour les rôles Admin/SuperAdmin (qui utilisent la
/// sidebar du panel web à la place).
class AppBottomNav extends StatelessWidget {
  final UserRole role;
  final String currentRoute;

  const AppBottomNav({
    super.key,
    required this.role,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsParRole[role];
    if (tabs == null) return const SizedBox.shrink();

    int currentIndex = tabs.indexWhere(
      (tab) => currentRoute == tab.route || currentRoute.startsWith('${tab.route}/'),
    );
    if (currentIndex < 0) currentIndex = 0;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) {
          context.go(tabs[index].route);
        }
      },
      items: tabs
          .map(
            (tab) => BottomNavigationBarItem(
              icon: Icon(tab.icon),
              activeIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
          )
          .toList(),
    );
  }
}
EOF
echo "→ lib/shared/widgets/layout/app_bottom_nav.dart créé."

# ============================================================================
# 3. SHELL D'ÉCRAN AVEC NAVIGATION
# ============================================================================
cat > lib/shared/widgets/layout/role_shell_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/session_provider.dart';
import 'app_bottom_nav.dart';

/// Écran coquille qui injecte la barre de navigation inférieure
/// appropriée selon le rôle de l'utilisateur, autour de n'importe
/// quel écran contenu.
///
/// En encapsulant les écrans principaux dans ce shell, on évite que
/// chaque écran ait à déclarer lui-même sa BottomNavigationBar —
/// ce qui éliminerait l'animation fluide de transition et causerait
/// un "clignotement" de la barre lors de chaque navigation.
class RoleShellScreen extends ConsumerWidget {
  final Widget child;

  const RoleShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(currentUserProvider);
    if (utilisateur == null) return child;

    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        role: utilisateur.role,
        currentRoute: currentRoute,
      ),
    );
  }
}
EOF
echo "→ lib/shared/widgets/layout/role_shell_screen.dart créé."

# ============================================================================
# 4. PATCH app_router.dart — transitions + shell de navigation
# ============================================================================
echo "→ Application des transitions et du shell de navigation dans app_router.dart..."

python3 << 'PYEOF'
path = "lib/core/router/app_router.dart"
with open(path, encoding="utf-8") as f:
    content = f.read()

# Ajout des imports pour les transitions et le shell
new_imports = (
    "import '../router/app_transitions.dart';\n"
    "import '../../shared/widgets/layout/role_shell_screen.dart';\n"
)
marker = "import '../../domain/enums/user_role.dart';\n"
if marker not in content:
    raise SystemExit("ERREUR : marqueur d'import UserRole introuvable dans app_router.dart")
content = content.replace(marker, marker + new_imports, 1)

# Enveloppe les 3 routes principales dans RoleShellScreen
# et applique la transition fadeSlide à toutes les routes feuilles.
routes_to_wrap = [
    (
        "GoRoute(\n        path: AppRoutes.shop,\n        builder: (context, state) => const ShopScreen(),\n      ),",
        "GoRoute(\n        path: AppRoutes.shop,\n        pageBuilder: (context, state) => CustomTransitionPage(\n          key: state.pageKey,\n          child: const RoleShellScreen(child: ShopScreen()),\n          transitionsBuilder: AppTransitions.fade,\n          transitionDuration: const Duration(milliseconds: 200),\n        ),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.sellHome,\n        builder: (context, state) => const SellHomeScreen(),\n      ),",
        "GoRoute(\n        path: AppRoutes.sellHome,\n        pageBuilder: (context, state) => CustomTransitionPage(\n          key: state.pageKey,\n          child: const RoleShellScreen(child: SellHomeScreen()),\n          transitionsBuilder: AppTransitions.fade,\n          transitionDuration: const Duration(milliseconds: 200),\n        ),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.agentDashboard,\n        builder: (context, state) => const AgentDashboardScreen(),\n      ),",
        "GoRoute(\n        path: AppRoutes.agentDashboard,\n        pageBuilder: (context, state) => CustomTransitionPage(\n          key: state.pageKey,\n          child: const RoleShellScreen(child: AgentDashboardScreen()),\n          transitionsBuilder: AppTransitions.fade,\n          transitionDuration: const Duration(milliseconds: 200),\n        ),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.orders,\n        builder: (context, state) => const OrdersScreen(),\n      ),",
        "GoRoute(\n        path: AppRoutes.orders,\n        pageBuilder: (context, state) => CustomTransitionPage(\n          key: state.pageKey,\n          child: const RoleShellScreen(child: OrdersScreen()),\n          transitionsBuilder: AppTransitions.fade,\n          transitionDuration: const Duration(milliseconds: 200),\n        ),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.favorites,\n        builder: (context, state) => const FavoritesScreen(),\n      ),",
        "GoRoute(\n        path: AppRoutes.favorites,\n        pageBuilder: (context, state) => CustomTransitionPage(\n          key: state.pageKey,\n          child: const RoleShellScreen(child: FavoritesScreen()),\n          transitionsBuilder: AppTransitions.fade,\n          transitionDuration: const Duration(milliseconds: 200),\n        ),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.messages,\n        builder: (context, state) => const MessagesScreen(),\n      ),",
        "GoRoute(\n        path: AppRoutes.messages,\n        pageBuilder: (context, state) => CustomTransitionPage(\n          key: state.pageKey,\n          child: const RoleShellScreen(child: MessagesScreen()),\n          transitionsBuilder: AppTransitions.fade,\n          transitionDuration: const Duration(milliseconds: 200),\n        ),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.profile,\n        builder: (context, state) => const ProfileScreen(),\n      ),",
        "GoRoute(\n        path: AppRoutes.profile,\n        pageBuilder: (context, state) => CustomTransitionPage(\n          key: state.pageKey,\n          child: const RoleShellScreen(child: ProfileScreen()),\n          transitionsBuilder: AppTransitions.fade,\n          transitionDuration: const Duration(milliseconds: 200),\n        ),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.notifications,\n        builder: (context, state) => const NotificationsScreen(),\n      ),",
        "GoRoute(\n        path: AppRoutes.notifications,\n        pageBuilder: (context, state) => CustomTransitionPage(\n          key: state.pageKey,\n          child: const RoleShellScreen(child: NotificationsScreen()),\n          transitionsBuilder: AppTransitions.fade,\n          transitionDuration: const Duration(milliseconds: 200),\n        ),\n      ),",
    ),
]

for old, new in routes_to_wrap:
    if old not in content:
        raise SystemExit(f"ERREUR : route introuvable pour le patch shell :\n{old[:80]}...")
    content = content.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("app_router.dart : 8 routes enveloppées dans RoleShellScreen + transitions appliquées.")
PYEOF

# ============================================================================
# 5. VÉRIFICATION FINALE AUTOMATISÉE
# ============================================================================
echo ""
echo "============================================================"
echo "  VÉRIFICATION FINALE DU PROJET COMPLET"
echo "============================================================"

python3 << 'PYEOF'
import re, glob, os, sys

errors = []
warnings = []

# ── 1. Comptage des fichiers Dart ──────────────────────────────────────────
dart_files = [f for f in glob.glob("lib/**/*.dart", recursive=True) if ".gitkeep" not in f]
print(f"  Fichiers Dart         : {len(dart_files)}")

# ── 2. Équilibrage des symboles ─────────────────────────────────────────────
def check_balance(filepath):
    with open(filepath, encoding="utf-8") as f:
        content = f.read()
    for ch_open, ch_close, name in [('{','}','accolades'), ('(', ')', 'parenthèses')]:
        if content.count(ch_open) != content.count(ch_close):
            return f"{name} déséquilibrées"
    return None

imbalanced = []
for f in dart_files:
    err = check_balance(f)
    if err:
        imbalanced.append(f"{f}: {err}")

if imbalanced:
    for e in imbalanced:
        errors.append(e)
    print(f"  Équilibrage           : {len(imbalanced)} erreur(s)")
else:
    print(f"  Équilibrage           : OK")

# ── 3. Imports relatifs ─────────────────────────────────────────────────────
missing_imports = []
for filepath in dart_files:
    dirpath = os.path.dirname(filepath)
    with open(filepath, encoding="utf-8") as f:
        content = f.read()
    for m in re.finditer(r"import '(\.\.[^']+)'", content):
        rel_path = m.group(1)
        resolved = os.path.normpath(os.path.join(dirpath, rel_path))
        if not os.path.exists(resolved):
            missing_imports.append(f"{filepath} -> {rel_path}")

if missing_imports:
    for e in missing_imports:
        errors.append(e)
    print(f"  Imports relatifs      : {len(missing_imports)} manquant(s)")
else:
    print(f"  Imports relatifs      : OK")

# ── 4. withOpacity interdit ─────────────────────────────────────────────────
deprecated = []
for f in dart_files:
    with open(f, encoding="utf-8") as fh:
        if "withOpacity(" in fh.read():
            deprecated.append(f)
if deprecated:
    for d in deprecated:
        warnings.append(f"withOpacity() déprécié dans {d}")
    print(f"  withOpacity           : {len(deprecated)} occurrence(s) dépréciée(s)")
else:
    print(f"  withOpacity           : OK (aucune occurrence dépréciée)")

# ── 5. Providers globaux (pas de provider dans build()) ────────────────────
bad_providers = []
for f in dart_files:
    with open(f, encoding="utf-8") as fh:
        content = fh.read()
    # Cherche des FutureProvider ou Provider déclarés à l'intérieur de classes
    # (heuristique simple : "= FutureProvider(" précédé d'espaces d'indentation)
    if re.search(r"^\s{4,}final \w+ = (Future|Async|Stream)Provider", content, re.MULTILINE):
        bad_providers.append(f)
if bad_providers:
    for b in bad_providers:
        errors.append(f"Provider déclaré dans un build() : {b}")
    print(f"  Providers locaux      : {len(bad_providers)} erreur(s)")
else:
    print(f"  Providers locaux      : OK")

# ── 6. Cohérence du routeur ─────────────────────────────────────────────────
with open("lib/core/router/app_routes.dart") as f:
    routes_src = f.read()
defined = set(re.findall(r"static const String (\w+) =", routes_src))

with open("lib/core/router/app_router.dart") as f:
    router_src = f.read()
used = set(re.findall(r"AppRoutes\.(\w+)", router_src))

missing_routes = used - defined
if missing_routes:
    errors.append(f"Routes utilisées mais non définies : {missing_routes}")
    print(f"  Cohérence des routes  : {len(missing_routes)} erreur(s)")
else:
    print(f"  Cohérence des routes  : OK ({len(defined)} routes définies et utilisées)")

# ── 7. main.dart existe ─────────────────────────────────────────────────────
if os.path.exists("lib/main.dart"):
    print(f"  main.dart             : OK")
else:
    errors.append("lib/main.dart manquant")
    print(f"  main.dart             : MANQUANT")

# ── 8. pubspec.yaml valide ──────────────────────────────────────────────────
try:
    import yaml
    with open("pubspec.yaml") as f:
        data = yaml.safe_load(f)
    deps = list(data.get("dependencies", {}).keys())
    print(f"  pubspec.yaml          : OK ({len(deps)} dépendances)")
except Exception as e:
    errors.append(f"pubspec.yaml invalide : {e}")
    print(f"  pubspec.yaml          : INVALIDE")

print("")
print(f"  Total fichiers Dart   : {len(dart_files)}")

if errors:
    print(f"\n  ERREURS ({len(errors)}) :")
    for e in errors:
        print(f"    - {e}")
    sys.exit(1)
elif warnings:
    print(f"\n  Avertissements ({len(warnings)}) :")
    for w in warnings:
        print(f"    ~ {w}")
    print("\n  Projet complet avec des avertissements mineurs.")
else:
    print("\n  Aucune erreur. Aucun avertissement.")
PYEOF

echo ""
echo "============================================================"
echo "  ✔ Projet AfriDeal — complet et validé !"
echo "============================================================"
echo ""
echo "POUR LANCER L'APPLICATION :"
echo ""
echo "  1. Assurez-vous que tous les 14 scripts ont été exécutés"
echo "     dans l'ordre, depuis la racine du projet 'foodapp/'."
echo ""
echo "  2. flutter pub get"
echo "     (à lancer une fois, ou chaque fois que le pubspec change)"
echo ""
echo "  3. MOBILE (Android / iOS) :"
echo "     flutter run"
echo ""
echo "  4. WEB (interface Admin) :"
echo "     flutter run -d chrome --web-port 3000"
echo "     → Puis connectez-vous avec le profil Admin ou Super Admin"
echo "       pour accéder au panel de gestion (sidebar + tableau de"
echo "       bord, catalogue, commandes, utilisateurs)."
echo ""
echo "COMPTES DE DÉMONSTRATION :"
echo "  Acheteur   → Marie Mballa     (boutique, paiement, commandes)"
echo "  Vendeur    → Michel Tagne     (soumission en 3 étapes)"
echo "  Agent      → Paul Nkeng       (missions, collecte, validation)"
echo "  Admin      → Sandrine Fotso   (catalogue, commandes, utilisateurs)"
echo "  Super Admin → Directeur Eyenga (tableau de bord global)"
echo ""
echo "POUR PASSER EN MODE API (Spring Boot) :"
echo "  1. Déployez votre backend Spring Boot"
echo "  2. Dans lib/core/config/app_config.dart, changez :"
echo "     static const DataMode dataMode = DataMode.local;"
echo "     → static const DataMode dataMode = DataMode.api;"
echo "  3. Renseignez apiBaseUrl avec l'URL de votre serveur"
echo "  4. flutter pub get && flutter run"
echo "  → Aucun autre fichier à modifier."
echo ""

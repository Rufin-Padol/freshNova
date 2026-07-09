import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
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
/// Aucun onglet "Vendre" dédié : n'importe quel utilisateur connecté
/// peut aussi bien acheter que soumettre un bien, depuis son profil.
/// L'Admin et le Super Admin n'ont pas de barre inférieure —
/// ils naviguent via la sidebar (AdminSidebar, script 13).
const List<_NavTab> _tabsAcheteur = [
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
];

const Map<UserRole, List<_NavTab>> _tabsParRole = {
  UserRole.acheteur: _tabsAcheteur,
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

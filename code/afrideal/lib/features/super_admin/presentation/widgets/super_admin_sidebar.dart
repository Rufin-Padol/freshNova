import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/session_provider.dart';

/// Navigation latérale du panel Super Admin — contrôle total de la
/// plateforme, y compris la gestion des comptes Admin.
class SuperAdminSidebar extends ConsumerWidget {
  final String currentRoute;
  const SuperAdminSidebar({super.key, required this.currentRoute});

  static const _itemsSuperAdmin = [
    _NavItem(Icons.dashboard_rounded, 'Vue globale', AppRoutes.superAdminDashboard),
    _NavItem(Icons.admin_panel_settings_outlined, 'Administrateurs', AppRoutes.superAdminAdmins),
    _NavItem(Icons.percent_rounded, 'Commissions', AppRoutes.superAdminCommissions),
  ];

  // Le Super Admin doit pouvoir faire tout ce que fait un Admin — ces
  // routes sont déjà autorisées pour son rôle par le routeur (voir
  // _cheminAutorisePourRole), il ne manquait qu'un point d'entrée
  // dans la navigation pour y accéder.
  static const _itemsAdmin = [
    _NavItem(Icons.inventory_2_outlined, 'Catalogue', AppRoutes.adminCatalog),
    _NavItem(Icons.assignment_outlined, 'Demandes vendeurs', AppRoutes.adminSellerRequests),
    _NavItem(Icons.chat_bubble_outline_rounded, 'Messages', AppRoutes.adminMessages),
    _NavItem(Icons.receipt_long_outlined, 'Commandes', AppRoutes.adminOrders),
    _NavItem(Icons.people_outline_rounded, 'Utilisateurs', AppRoutes.adminUsers),
    _NavItem(Icons.gavel_rounded, 'Litiges', AppRoutes.adminDisputes),
    _NavItem(Icons.route_outlined, 'Agents', AppRoutes.adminAgents),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(right: BorderSide(color: AppColors.gray800)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TrustNova',
                      style: AppTypography.titleLarge.copyWith(color: AppColors.white)),
                  Text('Super Administration',
                      style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                ],
              ),
            ),
            const Divider(color: AppColors.gray800, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ..._itemsSuperAdmin.map((item) {
                    final selected = currentRoute.startsWith(item.route);
                    return _SidebarTile(item: item, selected: selected);
                  }),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      'ADMINISTRATION',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  ..._itemsAdmin.map((item) {
                    final selected = currentRoute.startsWith(item.route);
                    return _SidebarTile(item: item, selected: selected);
                  }),
                ],
              ),
            ),
            const Divider(color: AppColors.gray800, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.gray400, size: 20),
              title: Text('Déconnexion',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.gray400)),
              onTap: () => ref.read(sessionProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _SidebarTile({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.violet.withValues(alpha: 0.15) : null,
        borderRadius: AppRadius.smRadius,
      ),
      child: ListTile(
        leading: Icon(item.icon,
            color: selected ? AppColors.violet : AppColors.gray400, size: 20),
        title: Text(
          item.label,
          style: AppTypography.bodyMedium.copyWith(
            color: selected ? AppColors.white : AppColors.gray400,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () => context.go(item.route),
        dense: true,
      ),
    );
  }
}

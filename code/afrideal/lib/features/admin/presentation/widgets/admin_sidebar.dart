import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation latérale du panel Admin, utilisée à la fois sur le
/// web (sidebar fixe à gauche) et en repli sur mobile (Drawer).
class AdminSidebar extends ConsumerWidget {
  final String currentRoute;
  const AdminSidebar({super.key, required this.currentRoute});

  static const _items = [
    _NavItem(Icons.dashboard_rounded, 'Tableau de bord', AppRoutes.adminDashboard),
    _NavItem(Icons.inventory_2_outlined, 'Catalogue', AppRoutes.adminCatalog),
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
                  Text('AfriDeal',
                      style: AppTypography.titleLarge.copyWith(color: AppColors.white)),
                  Text('Administration',
                      style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                ],
              ),
            ),
            const Divider(color: AppColors.gray800, height: 1),
            const SizedBox(height: AppSpacing.sm),
            ...AdminSidebar._items.map((item) {
              final selected = currentRoute.startsWith(item.route);
              return _SidebarTile(item: item, selected: selected);
            }),
            const Spacer(),
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

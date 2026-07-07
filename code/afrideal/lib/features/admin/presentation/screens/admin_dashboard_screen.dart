import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/enums/product_status.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitsAsync = ref.watch(allProductsAdminProvider);
    final usersAsync = ref.watch(allUsersAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau de bord', style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.xxl),
            produitsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement'),
              data: (produits) => Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _KpiCard(
                    titre: 'Produits en vente',
                    valeur: '${produits.where((p) => p.statut == ProductStatus.enVente).length}',
                    icon: Icons.storefront_rounded,
                    couleur: AppColors.success,
                  ),
                  _KpiCard(
                    titre: 'En attente',
                    valeur: '${produits.where((p) => p.statut == ProductStatus.soumis).length}',
                    icon: Icons.pending_rounded,
                    couleur: AppColors.gold,
                  ),
                  _KpiCard(
                    titre: 'En vérification',
                    valeur: '${produits.where((p) => p.statut == ProductStatus.enVerification).length}',
                    icon: Icons.manage_search_rounded,
                    couleur: AppColors.violet,
                  ),
                  usersAsync.when(
                    loading: () => const _KpiCard(titre: 'Utilisateurs', valeur: '…', icon: Icons.people_rounded, couleur: AppColors.blue),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (users) => _KpiCard(
                      titre: 'Utilisateurs',
                      valeur: '${users.length}',
                      icon: Icons.people_rounded,
                      couleur: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icon;
  final Color couleur;

  const _KpiCard({
    required this.titre,
    required this.valeur,
    required this.icon,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, color: couleur, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(valeur,
              style: AppTypography.displayMedium.copyWith(color: AppColors.black)),
          Text(titre, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

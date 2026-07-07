import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/super_admin_provider.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(superAdminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vue stratégique globale', style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Contrôle total de la plateforme — visible uniquement par le Super Admin.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            statsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement'),
              data: (stats) => Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _KpiCard(
                    titre: 'Revenus commissions',
                    valeur: Formatters.currency(stats.revenusCommissions),
                    icon: Icons.account_balance_wallet_rounded,
                    couleur: AppColors.violet,
                  ),
                  _KpiCard(
                    titre: 'Utilisateurs',
                    valeur: '${stats.totalUtilisateurs}',
                    icon: Icons.people_rounded,
                    couleur: AppColors.blue,
                  ),
                  _KpiCard(
                    titre: 'Produits en vente',
                    valeur: '${stats.totalProduitsEnVente}',
                    icon: Icons.storefront_rounded,
                    couleur: AppColors.success,
                  ),
                  _KpiCard(
                    titre: 'Commandes livrées',
                    valeur: '${stats.totalCommandesLivrees}',
                    icon: Icons.local_shipping_rounded,
                    couleur: AppColors.gold,
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
      width: 200,
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
          Text(valeur, style: AppTypography.displayMedium.copyWith(color: AppColors.black)),
          Text(titre, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

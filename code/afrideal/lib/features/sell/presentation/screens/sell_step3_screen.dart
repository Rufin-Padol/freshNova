import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../providers/sell_provider.dart';

class SellStep3Screen extends ConsumerWidget {
  const SellStep3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(sellProvider);

    if (form.estEnvoye) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(AppRoutes.sellConfirmation),
      );
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendre un produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.sellStep2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressSteps(steps: const ['Description', 'Logistique', 'Récapitulatif'], currentIndex: 2),
            const SizedBox(height: AppSpacing.xxl),
            Text('Récapitulatif', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.xs),
            Text('Vérifiez les informations avant d\'envoyer.', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                children: [
                  InfoRow(icon: Icons.inventory_2_outlined, label: 'Produit', value: form.typeProduit),
                  const Divider(height: AppSpacing.xl),
                  InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Prix souhaité',
                    value: Formatters.currency(form.prixSouhaite),
                  ),
                  const Divider(height: AppSpacing.xl),
                  InfoRow(icon: Icons.location_on_outlined, label: 'Adresse', value: form.adresse),
                  const Divider(height: AppSpacing.xl),
                  InfoRow(icon: Icons.schedule_outlined, label: 'Disponibilité', value: form.disponibilite),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.goldSurface,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Une commission de 8 à 25 % sera déduite du prix de vente final selon la catégorie.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.goldDark),
                    ),
                  ),
                ],
              ),
            ),
            if (form.erreur != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(form.erreur!, style: AppTypography.bodyMedium.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppPrimaryButton(
            label: 'Envoyer ma demande',
            icon: Icons.send_rounded,
            isLoading: form.estEnvoi,
            onPressed: form.estEnvoi ? null : () => ref.read(sellProvider.notifier).soumettre(),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../../../shared/widgets/map/location_picker_map.dart';
import '../../providers/sell_provider.dart';

class SellStep2Screen extends ConsumerWidget {
  const SellStep2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(sellProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendre un produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.sellStep1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressSteps(steps: const ['Description', 'Logistique', 'Récapitulatif'], currentIndex: 1),
            const SizedBox(height: AppSpacing.xxl),
            Text('Collecte à domicile', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Un agent se déplacera chez vous pour vérifier et récupérer votre produit.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Adresse de collecte',
              hint: 'Quartier, rue, point de repère...',
              initialValue: form.adresse,
              onChanged: ref.read(sellProvider.notifier).setAdresse,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Zone (ville / arrondissement)',
              hint: 'Ex : Douala, Akwa',
              initialValue: form.zone,
              onChanged: ref.read(sellProvider.notifier).setZone,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Disponibilité',
              hint: 'Ex : Lundi-Vendredi après 17h, ou week-end toute la journée',
              maxLines: 2,
              initialValue: form.disponibilite,
              onChanged: ref.read(sellProvider.notifier).setDisponibilite,
            ),
            const SizedBox(height: AppSpacing.xl),
            LocationPickerMap(
              latitudeInitiale: form.latitude,
              longitudeInitiale: form.longitude,
              onPositionChoisie: ref.read(sellProvider.notifier).setPosition,
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.violetSurface,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.violet, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'L\'agent se présentera avec son badge TrustNova. '
                      'Votre identité et la propriété du produit seront vérifiées.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.violetDark),
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
            label: 'Continuer',
            onPressed: () {
              if (ref.read(sellProvider.notifier).validerEtape2()) {
                context.go(AppRoutes.sellStep3);
              }
            },
          ),
        ),
      ),
    );
  }
}

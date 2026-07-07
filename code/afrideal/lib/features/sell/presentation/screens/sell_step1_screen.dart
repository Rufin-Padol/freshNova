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
import '../../../shop/providers/category_provider.dart';
import '../../providers/sell_provider.dart';

class SellStep1Screen extends ConsumerWidget {
  const SellStep1Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(sellProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendre un produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.sellHome),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressSteps(steps: const ['Description', 'Logistique', 'Récapitulatif'], currentIndex: 0),
            const SizedBox(height: AppSpacing.xxl),
            Text('Description du produit', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.xs),
            Text('Dites-nous ce que vous souhaitez vendre.', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Nom du produit',
              hint: 'Ex : iPhone 12, Chaise scandinave...',
              initialValue: form.typeProduit,
              onChanged: ref.read(sellProvider.notifier).setTypeProduit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Catégorie', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Impossible de charger les catégories.'),
              data: (cats) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: cats.map((cat) {
                  final sel = form.categorieId == cat.id;
                  return ChoiceChip(
                    label: Text(cat.nom),
                    selected: sel,
                    onSelected: (_) => ref.read(sellProvider.notifier).setCategorieId(cat.id),
                    selectedColor: AppColors.violetSurface,
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: sel ? AppColors.violet : AppColors.gray700,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Prix souhaité (FCFA)',
              hint: 'Ex : 50000',
              keyboardType: TextInputType.number,
              initialValue: form.prixSouhaite > 0 ? form.prixSouhaite.toInt().toString() : '',
              onChanged: ref.read(sellProvider.notifier).setPrix,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Description',
              hint: 'État, accessoires inclus, défauts éventuels...',
              maxLines: 4,
              initialValue: form.description,
              onChanged: ref.read(sellProvider.notifier).setDescription,
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
              if (ref.read(sellProvider.notifier).validerEtape1()) {
                context.go(AppRoutes.sellStep2);
              }
            },
          ),
        ),
      ),
    );
  }
}

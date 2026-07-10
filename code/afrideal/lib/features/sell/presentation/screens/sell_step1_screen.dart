import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/progress_steps.dart';
import '../../../shop/providers/category_provider.dart';
import '../../providers/sell_provider.dart';

Uint8List _decodeDataUrl(String dataUrl) => base64Decode(dataUrl.split(',').last);

Future<String?> _capturerPhoto(ImageSource source) async {
  try {
    final xfile = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (xfile == null) return null;
    final bytes = await xfile.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  } catch (_) {
    return null;
  }
}

class SellStep1Screen extends ConsumerWidget {
  const SellStep1Screen({super.key});

  Future<void> _ajouterPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final dataUrl = await _capturerPhoto(source);
    if (dataUrl != null) ref.read(sellProvider.notifier).ajouterPhoto(dataUrl);
  }

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
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Photos du produit '
              '(${AppConstants.minSellerPreviewPhotos} min. — ${AppConstants.maxSellerPreviewPhotos} max.)',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Quelques photos suffisent pour que l\'admin évalue votre demande '
              'avant d\'envoyer un agent chez vous.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < form.photos.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.smRadius,
                        child: Image.memory(
                          _decodeDataUrl(form.photos[i]),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => ref.read(sellProvider.notifier).retirerPhoto(i),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.danger,
                            child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (form.photos.length < AppConstants.maxSellerPreviewPhotos)
                  InkWell(
                    onTap: () => _ajouterPhoto(context, ref),
                    borderRadius: AppRadius.smRadius,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.violetSurface,
                        borderRadius: AppRadius.smRadius,
                        border: Border.all(color: AppColors.violet),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: AppColors.violet),
                    ),
                  ),
              ],
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

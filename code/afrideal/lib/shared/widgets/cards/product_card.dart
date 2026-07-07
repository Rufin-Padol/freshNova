import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../illustrations/empty_image_illustration.dart';

/// Carte produit affichée dans les grilles de la boutique, des
/// favoris, et des listes vendeur/agent.
///
/// Volontairement compacte : seules les informations essentielles à
/// la décision d'achat sont visibles (photo, titre, prix, localisation).
/// Le détail complet n'apparaît que sur la fiche produit.
class ProductCard extends StatelessWidget {
  final String titre;
  final double prix;
  final String? photoUrl;
  final String localisation;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool estFavori;

  const ProductCard({
    super.key,
    required this.titre,
    required this.prix,
    required this.localisation,
    required this.onTap,
    this.photoUrl,
    this.onFavoriteTap,
    this.estFavori = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.gray200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: photoUrl != null && photoUrl!.isNotEmpty
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const EmptyImageIllustration(),
                        )
                      : const EmptyImageIllustration(),
                ),
                if (onFavoriteTap != null)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          estFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: estFavori ? AppColors.danger : AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(prix),
                    style: AppTypography.titleMedium.copyWith(color: AppColors.violet),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.gray400),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          localisation,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

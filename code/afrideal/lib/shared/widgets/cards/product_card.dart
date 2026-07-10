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
/// la décision d'achat sont visibles (photo, titre, prix). Ni la
/// localisation ni le vendeur ne sont affichés — TrustNova est
/// l'unique interlocuteur visible de l'acheteur, sur la carte comme
/// sur la fiche produit. Pas de note ni de "stock restant" : chaque
/// annonce est un bien de seconde main unique, pas un article en
/// stock avec avis clients.
class ProductCard extends StatelessWidget {
  final String titre;
  final double prix;
  final String? photoUrl;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool estFavori;
  final VoidCallback? onCartTap;
  final bool estDansPanier;

  const ProductCard({
    super.key,
    required this.titre,
    required this.prix,
    required this.onTap,
    this.photoUrl,
    this.onFavoriteTap,
    this.estFavori = false,
    this.onCartTap,
    this.estDansPanier = false,
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
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
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
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.card,
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
              ),
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
                ],
              ),
            ),
            if (onCartTap != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                ),
                child: _AddToCartButton(
                  dansLePanier: estDansPanier,
                  onTap: onCartTap!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final bool dansLePanier;
  final VoidCallback onTap;

  const _AddToCartButton({required this.dansLePanier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 34,
        decoration: BoxDecoration(
          color: dansLePanier ? AppColors.violetSurface : AppColors.violet,
          borderRadius: AppRadius.smRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              dansLePanier ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
              size: 15,
              color: dansLePanier ? AppColors.violet : AppColors.white,
            ),
            const SizedBox(width: 6),
            Text(
              dansLePanier ? 'Dans le panier' : 'Ajouter au panier',
              style: AppTypography.bodySmall.copyWith(
                color: dansLePanier ? AppColors.violet : AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

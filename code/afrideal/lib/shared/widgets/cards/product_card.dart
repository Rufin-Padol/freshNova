import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../illustrations/empty_image_illustration.dart';

/// Carte produit affichée dans les listes de la boutique et des
/// favoris — une carte par ligne (jamais de grille à deux colonnes :
/// une grille serrée forçait une hauteur fixe par carte, ce qui
/// débordait dès que le contenu dépassait l'espace prévu). En liste
/// pleine largeur, la carte s'adapte naturellement à son contenu, sans
/// contrainte de hauteur imposée depuis l'extérieur.
///
/// Affiche la localisation générale du produit (ville/quartier) —
/// utile pour évaluer la faisabilité d'une livraison — mais jamais
/// l'identité du vendeur : TrustNova reste l'unique interlocuteur
/// visible de l'acheteur. Pas de note ni de "stock restant" non plus,
/// chaque annonce étant un bien de seconde main unique.
class ProductCard extends StatelessWidget {
  final String titre;
  final double prix;
  final String? photoUrl;
  final String? localisation;
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
    this.localisation,
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
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.mdRadius,
              child: SizedBox(
                width: 108,
                height: 108,
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const EmptyImageIllustration(),
                      )
                    : const EmptyImageIllustration(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          titre,
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onFavoriteTap != null)
                        GestureDetector(
                          onTap: onFavoriteTap,
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.xs),
                            child: Icon(
                              estFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 18,
                              color: estFavori ? AppColors.danger : AppColors.gray400,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(prix),
                    style: AppTypography.titleMedium.copyWith(color: AppColors.violet),
                  ),
                  if (localisation != null && localisation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.gray400),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            localisation!,
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (onCartTap != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _AddToCartButton(dansLePanier: estDansPanier, onTap: onCartTap!),
                  ],
                ],
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
        height: 32,
        decoration: BoxDecoration(
          color: dansLePanier ? AppColors.violetSurface : AppColors.violet,
          borderRadius: AppRadius.smRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              dansLePanier ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
              size: 14,
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

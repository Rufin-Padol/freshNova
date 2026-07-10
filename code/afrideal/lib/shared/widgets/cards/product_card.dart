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
/// contrainte de hauteur imposée depuis l'extérieur. Photo en haut,
/// informations en dessous — jamais côte à côte.
///
/// Affiche la localisation générale du produit (ville/quartier) —
/// utile pour évaluer la faisabilité d'une livraison — mais jamais
/// l'identité du vendeur : TrustNova reste l'unique interlocuteur
/// visible de l'acheteur. Affiche aussi la quantité disponible : un
/// propriétaire peut avoir plusieurs exemplaires identiques d'un même
/// bien, une annonce n'est donc pas toujours un article unique.
class ProductCard extends StatelessWidget {
  final String titre;
  final double prix;
  final String? photoUrl;
  final String? localisation;
  final int quantiteDisponible;
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
    this.quantiteDisponible = 1,
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
                  aspectRatio: 16 / 10,
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
                if (estDansPanier)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.violet,
                        borderRadius: AppRadius.fullRadius,
                        boxShadow: AppShadows.card,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 13, color: AppColors.white),
                          SizedBox(width: 3),
                          Text(
                            'Au panier',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                  Text(
                    quantiteDisponible > 0
                        ? '$quantiteDisponible disponible${quantiteDisponible > 1 ? 's' : ''}'
                        : 'Épuisé',
                    style: AppTypography.caption.copyWith(
                      color: quantiteDisponible > 0 ? AppColors.gray500 : AppColors.danger,
                      fontWeight: quantiteDisponible > 0 ? FontWeight.w400 : FontWeight.w600,
                    ),
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
                  if (onCartTap != null && (quantiteDisponible > 0 || estDansPanier)) ...[
                    const SizedBox(height: AppSpacing.md),
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
        height: 38,
        decoration: BoxDecoration(
          color: dansLePanier ? AppColors.violetSurface : AppColors.violet,
          borderRadius: AppRadius.smRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              dansLePanier ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
              size: 16,
              color: dansLePanier ? AppColors.violet : AppColors.white,
            ),
            const SizedBox(width: 6),
            Text(
              dansLePanier ? 'Dans le panier' : 'Ajouter au panier',
              style: AppTypography.bodyMedium.copyWith(
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

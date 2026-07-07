import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/categorie.dart';

/// Icônes Material associées à chaque catégorie de démonstration.
/// En l'absence d'icônes SVG dédiées par catégorie, ce mapping garde
/// un rendu professionnel et cohérent à travers la boutique.
IconData _iconePourCategorie(String nom) {
  switch (nom) {
    case 'Électronique':
      return Icons.smartphone_rounded;
    case 'Mode':
      return Icons.checkroom_rounded;
    case 'Maison':
      return Icons.chair_rounded;
    case 'Véhicules':
      return Icons.directions_car_rounded;
    default:
      return Icons.category_rounded;
  }
}

/// Rangée horizontale de catégories avec sélection, utilisée en haut
/// de la boutique. Reprend la disposition de la maquette (icône
/// ronde + libellé sous chaque catégorie).
class CategorySelector extends StatelessWidget {
  final List<Categorie> categories;
  final String? selectedId;
  final void Function(String?) onSelect;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, index) {
          final categorie = categories[index];
          final estSelectionne = selectedId == categorie.id;
          return GestureDetector(
            onTap: () => onSelect(estSelectionne ? null : categorie.id),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: estSelectionne ? AppColors.violet : AppColors.violetSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconePourCategorie(categorie.nom),
                    color: estSelectionne ? AppColors.white : AppColors.violet,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(categorie.nom, style: AppTypography.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}

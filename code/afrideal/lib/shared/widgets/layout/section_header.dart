import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// En-tête de section avec titre et action optionnelle ("Voir tout"),
/// utilisé pour structurer les écrans à plusieurs sections (accueil
/// boutique : Catégories, Annonces récentes...).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headline),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.violet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

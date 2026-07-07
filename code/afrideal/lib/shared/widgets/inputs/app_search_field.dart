import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Champ de recherche standardisé, utilisé en haut de la boutique et
/// des écrans de catalogue/listing.
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final void Function(String)? onChanged;
  final VoidCallback? onFilterTap;

  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Rechercher un produit...',
    this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.lg),
          const Icon(Icons.search_rounded, color: AppColors.gray400, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
            ),
          ),
          if (onFilterTap != null)
            IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune_rounded, color: AppColors.violet),
            ),
        ],
      ),
    );
  }
}

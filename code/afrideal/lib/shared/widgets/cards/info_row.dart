import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Ligne d'information libellé/valeur, utilisée dans les écrans de
/// détail (fiche produit, détail commande, détail mission...) pour
/// présenter des informations structurées de façon cohérente partout
/// dans l'application.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.gray400),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.bodyLarge.copyWith(color: AppColors.black)),
            ],
          ),
        ),
      ],
    );
  }
}

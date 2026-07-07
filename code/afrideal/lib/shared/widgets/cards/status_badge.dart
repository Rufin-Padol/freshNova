import 'package:flutter/material.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Badge coloré affichant un statut (produit, commande, mission...).
/// La couleur est entièrement déterminée par l'appelant, ce qui
/// permet de réutiliser ce SEUL widget pour tous les types de statuts
/// de l'application (chacun ayant déjà sa propre couleur définie dans
/// son enum, voir script 03).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

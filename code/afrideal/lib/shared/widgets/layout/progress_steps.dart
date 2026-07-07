import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Barre de progression par étapes, utilisée pour visualiser le cycle
/// de vie d'un produit ou d'une mission (ex: Soumis → Collecté →
/// En vente → Livré), et pour les formulaires en plusieurs étapes
/// (soumission vendeur en 3 étapes).
class ProgressSteps extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const ProgressSteps({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepBefore = i ~/ 2;
          final estFranchi = stepBefore < currentIndex;
          return Expanded(
            child: Container(
              height: 3,
              color: estFranchi ? AppColors.violet : AppColors.gray200,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final estActif = stepIndex == currentIndex;
        final estComplete = stepIndex < currentIndex;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: estComplete || estActif ? AppColors.violet : AppColors.gray200,
              ),
              alignment: Alignment.center,
              child: estComplete
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: AppTypography.bodySmall.copyWith(
                        color: estActif ? AppColors.white : AppColors.gray500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

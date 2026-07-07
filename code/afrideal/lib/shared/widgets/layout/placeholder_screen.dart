import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../illustrations/onboarding_illustrations.dart';

/// Écran temporaire affiché pour toute route dont l'écran définitif
/// n'a pas encore été construit.
///
/// Ce widget est volontairement TRÈS visible (bandeau orange) pour
/// qu'il soit impossible de le confondre avec un écran terminé
/// pendant les tests manuels de l'application au fil des scripts.
/// Il sera remplacé, route par route, par les scripts 10 à 13.
class PlaceholderScreen extends StatelessWidget {
  final String titre;

  const PlaceholderScreen({super.key, required this.titre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyBoxIllustration(size: 100),
              const SizedBox(height: 20),
              Text(titre, style: AppTypography.headline, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Cet écran sera construit dans un prochain script.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

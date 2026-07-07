import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Indicateur de chargement standardisé, centré dans son espace
/// disponible. Utilisé à la place du CircularProgressIndicator brut
/// pour garantir une couleur et une taille cohérentes partout.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;

  const AppLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: AppColors.gray500)),
          ],
        ],
      ),
    );
  }
}

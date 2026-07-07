import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Fonctions utilitaires pour afficher des messages temporaires
/// cohérents dans toute l'application (succès, erreur, information),
/// plutôt que de construire un SnackBar différemment à chaque écran.
class AppSnackbar {
  AppSnackbar._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.danger, Icons.error_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.blue, Icons.info_rounded);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

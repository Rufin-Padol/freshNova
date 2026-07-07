import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// Vue d'erreur générique, affichée à la place du contenu lorsqu'un
/// chargement de données échoue.
///
/// Toujours accompagnée d'une action claire ("Réessayer") : l'utilisateur
/// ne doit jamais se retrouver bloqué face à un écran sans recours.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.dangerSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.danger, size: 30),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vue affichée lorsqu'une liste est vide (aucun produit, aucune
/// commande...). Distincte de [ErrorView] car ce n'est pas une erreur :
/// c'est un état normal qui mérite un message rassurant, pas alarmant.
class EmptyView extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gray400, size: 32),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

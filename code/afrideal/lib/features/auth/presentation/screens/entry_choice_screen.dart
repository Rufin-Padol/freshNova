import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/illustrations/onboarding_illustrations.dart';

/// Écran de bienvenue, premier écran vu par tout nouvel utilisateur.
///
/// Reprend l'identité visuelle TrustNova validée : dégradé violet-bleu,
/// message de confiance et sécurité, illustration vectorielle de
/// bouclier — fidèle à la maquette fournie.
class EntryChoiceScreen extends StatelessWidget {
  const EntryChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                const Spacer(),
                const TrustShieldIllustration(size: 140),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'TrustNova',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.white,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Seconde main, première confiance.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Achetez et vendez des produits d\'occasion en toute sécurité. '
                  'Chaque transaction est vérifiée par nos agents terrain.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: AppPrimaryButton(
                    label: 'Découvrir TrustNova',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.go(AppRoutes.demoAccounts),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: Text(
                    'J\'ai déjà un compte — Se connecter',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

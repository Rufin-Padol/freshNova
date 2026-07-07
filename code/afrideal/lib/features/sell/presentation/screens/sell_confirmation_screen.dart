import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/illustrations/onboarding_illustrations.dart';
import '../../providers/sell_provider.dart';

class SellConfirmationScreen extends ConsumerWidget {
  const SellConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SuccessIllustration(size: 130),
              const SizedBox(height: AppSpacing.xl),
              Text('Demande envoyée !', style: AppTypography.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nous avons bien reçu votre demande. Un administrateur va l\'examiner '
                'et un agent terrain sera bientôt en contact avec vous pour convenir '
                'd\'un rendez-vous de collecte.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              _EtapeItem(
                icon: Icons.manage_search_rounded,
                color: AppColors.gold,
                titre: 'Validation',
                description: 'Un admin examine votre demande sous 24h.',
              ),
              const SizedBox(height: AppSpacing.md),
              _EtapeItem(
                icon: Icons.person_pin_circle_outlined,
                color: AppColors.blue,
                titre: 'Collecte',
                description: 'Un agent vous rend visite pour vérifier votre produit.',
              ),
              const SizedBox(height: AppSpacing.md),
              _EtapeItem(
                icon: Icons.storefront_outlined,
                color: AppColors.success,
                titre: 'Mise en vente',
                description: 'Votre produit est publié et visible dans la boutique.',
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppPrimaryButton(
                label: 'Voir mes demandes',
                onPressed: () {
                  ref.read(sellProvider.notifier).reset();
                  context.go(AppRoutes.sellHome);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'Soumettre un autre produit',
                onPressed: () {
                  ref.read(sellProvider.notifier).reset();
                  context.go(AppRoutes.sellStep1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtapeItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titre;
  final String description;

  const _EtapeItem({
    required this.icon,
    required this.color,
    required this.titre,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: AppTypography.titleMedium),
              Text(description, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

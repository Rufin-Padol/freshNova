import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../domain/enums/order_status.dart';
import '../../../../domain/enums/payment_status.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/illustrations/onboarding_illustrations.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/checkout_provider.dart';

/// Écran de paiement, déclenché depuis la fiche produit.
///
/// Reçoit le produit à acheter directement (plutôt que de passer par
/// un identifiant et un nouveau chargement), car au moment où
/// l'utilisateur arrive ici, le produit est déjà chargé en mémoire
/// par l'écran précédent — évite un aller-retour réseau inutile,
/// important pour la fluidité sur connexion lente.
class CheckoutScreen extends ConsumerWidget {
  final Produit produit;

  const CheckoutScreen({super.key, required this.produit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutProvider);

    if (state.step == CheckoutStep.succes) {
      return _CheckoutSuccessView(produit: produit);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paiement sécurisé')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(produit.titre, style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(produit.prix),
                          style: AppTypography.titleLarge.copyWith(color: AppColors.violet),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Mode de livraison', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _DeliveryModeSelector(
              selected: state.modeLivraison,
              onChanged: (mode) => ref.read(checkoutProvider.notifier).setModeLivraison(mode),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Adresse de livraison',
              hint: 'Quartier, rue, point de repère...',
              onChanged: (v) => ref.read(checkoutProvider.notifier).setAdresse(v),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Méthode de paiement', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _PaymentMethodSelector(
              selected: state.methode,
              onChanged: (methode) => ref.read(checkoutProvider.notifier).setMethode(methode),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Numéro Mobile Money',
              hint: '6XX XXX XXX',
              keyboardType: TextInputType.phone,
              onChanged: (v) => ref.read(checkoutProvider.notifier).setNumeroPaieur(v),
            ),
            if (state.messageErreur != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                state.messageErreur!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppPrimaryButton(
            label: state.step == CheckoutStep.traitement
                ? 'Confirmation en cours...'
                : 'Payer ${Formatters.currency(produit.prix)}',
            isLoading: state.step == CheckoutStep.traitement,
            onPressed: state.step == CheckoutStep.traitement
                ? null
                : () => ref.read(checkoutProvider.notifier).confirmerAchat(produit),
          ),
        ),
      ),
    );
  }
}

class _DeliveryModeSelector extends StatelessWidget {
  final DeliveryMode selected;
  final void Function(DeliveryMode) onChanged;

  const _DeliveryModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DeliveryMode.values.map((mode) {
        final estSelectionne = mode == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: mode == DeliveryMode.livraison ? AppSpacing.sm : 0),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: estSelectionne ? AppColors.violetSurface : AppColors.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: estSelectionne ? AppColors.violet : AppColors.gray200,
                    width: estSelectionne ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      mode == DeliveryMode.livraison
                          ? Icons.local_shipping_outlined
                          : Icons.storefront_outlined,
                      color: estSelectionne ? AppColors.violet : AppColors.gray500,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mode.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: estSelectionne ? AppColors.violet : AppColors.gray600,
                        fontWeight: estSelectionne ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final void Function(PaymentMethod) onChanged;

  const _PaymentMethodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PaymentMethod.values.map((methode) {
        final estSelectionne = methode == selected;
        final couleur = methode == PaymentMethod.orangeMoney
            ? const Color(0xFFFF6600)
            : const Color(0xFFFFCC00);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: methode == PaymentMethod.orangeMoney ? AppSpacing.sm : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(methode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: estSelectionne ? AppColors.violetSurface : AppColors.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: estSelectionne ? AppColors.violet : AppColors.gray200,
                    width: estSelectionne ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      methode.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: estSelectionne ? AppColors.violet : AppColors.gray600,
                        fontWeight: estSelectionne ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CheckoutSuccessView extends ConsumerWidget {
  final Produit produit;

  const _CheckoutSuccessView({required this.produit});

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
              const SuccessIllustration(size: 140),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Paiement confirmé !',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Votre achat de "${produit.titre}" a été sécurisé. '
                'Le vendeur a été notifié et votre produit sera bientôt en livraison.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppPrimaryButton(
                label: 'Suivre ma commande',
                onPressed: () {
                  ref.read(checkoutProvider.notifier).reset();
                  context.go(AppRoutes.orders);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

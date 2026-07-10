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
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/illustrations/onboarding_illustrations.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../providers/checkout_provider.dart';

/// Écran de paiement, déclenché depuis la fiche produit (un seul
/// article) ou depuis le panier (plusieurs articles à la fois).
///
/// Reçoit directement les produits à acheter (plutôt que de passer
/// par des identifiants et un nouveau chargement), car au moment où
/// l'utilisateur arrive ici, ils sont déjà chargés en mémoire par
/// l'écran précédent — évite un aller-retour réseau inutile, important
/// pour la fluidité sur connexion lente.
class CheckoutScreen extends ConsumerWidget {
  final List<Produit> produits;

  const CheckoutScreen({super.key, required this.produits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutProvider);

    if (state.step == CheckoutStep.succes) {
      return _CheckoutSuccessView(produits: produits);
    }

    final montantTotal = produits.fold<double>(0, (somme, p) => somme + p.prix);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Confirmer la commande')),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final produit in produits) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(produit.titre, style: AppTypography.titleMedium),
                        ),
                        Text(
                          Formatters.currency(produit.prix),
                          style: AppTypography.bodyLarge.copyWith(color: AppColors.gray700),
                        ),
                      ],
                    ),
                    if (produit != produits.last) const SizedBox(height: AppSpacing.sm),
                  ],
                  if (produits.length > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: AppTypography.titleMedium),
                        Text(
                          Formatters.currency(montantTotal),
                          style: AppTypography.titleLarge.copyWith(color: AppColors.violet),
                        ),
                      ],
                    ),
                  ],
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
            Text('Paiement à la livraison', style: AppTypography.titleLarge),
            const SizedBox(height: 2),
            Text(
              'Vous payez uniquement à la réception du produit — rien n\'est débité maintenant.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PaymentMethodSelector(
              selected: state.methode,
              onChanged: (methode) => ref.read(checkoutProvider.notifier).setMethode(methode),
            ),
            if (state.methode != PaymentMethod.especes) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Numéro Mobile Money',
                hint: '6XX XXX XXX',
                keyboardType: TextInputType.phone,
                onChanged: (v) => ref.read(checkoutProvider.notifier).setNumeroPaieur(v),
              ),
            ],
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
                : 'Confirmer — ${Formatters.currency(montantTotal)} à la livraison',
            isLoading: state.step == CheckoutStep.traitement,
            onPressed: state.step == CheckoutStep.traitement
                ? null
                : () => ref.read(checkoutProvider.notifier).confirmerAchat(produits),
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
    final methodes = PaymentMethod.values;
    return Row(
      children: [
        for (var i = 0; i < methodes.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _buildOption(methodes[i])),
        ],
      ],
    );
  }

  Widget _buildOption(PaymentMethod methode) {
    final estSelectionne = methode == selected;
    return GestureDetector(
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
            _buildIcone(methode),
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
    );
  }

  Widget _buildIcone(PaymentMethod methode) {
    if (methode == PaymentMethod.especes) {
      return const Icon(Icons.payments_outlined, size: 28, color: AppColors.gray700);
    }
    final couleur = methode == PaymentMethod.orangeMoney
        ? const Color(0xFFFF6600)
        : const Color(0xFFFFCC00);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
    );
  }
}

class _CheckoutSuccessView extends ConsumerWidget {
  final List<Produit> produits;

  const _CheckoutSuccessView({required this.produits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = produits.length == 1
        ? 'Votre achat de "${produits.first.titre}" est enregistré.'
        : 'Vos ${produits.length} articles sont enregistrés.';

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
                'Commande confirmée !',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$description Notre équipe s\'occupe de la livraison — '
                'vous payez à la réception.',
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
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: 'Continuer mes achats',
                onPressed: () {
                  ref.read(checkoutProvider.notifier).reset();
                  context.go(AppRoutes.shop);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

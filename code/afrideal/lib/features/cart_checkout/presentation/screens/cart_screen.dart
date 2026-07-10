import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/illustrations/empty_image_illustration.dart';
import '../../../auth/providers/session_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';

/// Panier de l'acheteur : liste des produits mis de côté avant achat,
/// avec une quantité par article (un propriétaire peut avoir
/// plusieurs exemplaires identiques d'un même bien, jamais plus que
/// [Produit.quantiteDisponible]). La commande se passe pour tout le
/// panier en une fois (un seul bouton "Commander" en bas, une seule
/// commande à la fin) — pas une commande séparée par article.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panierAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon panier')),
      body: panierAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger votre panier.',
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (panier) {
          if (panier.isEmpty) {
            return const EmptyView(
              message: 'Votre panier est vide',
              subtitle: 'Ajoutez un produit depuis sa fiche pour le retrouver ici.',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return _CartList(panier: panier);
        },
      ),
    );
  }
}

class _CartList extends ConsumerWidget {
  final Map<String, int> panier;

  const _CartList({required this.panier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productRepo = ref.watch(productRepositoryProvider);

    return FutureBuilder<List<Produit>>(
      future: Future.wait(panier.keys.map((id) => productRepo.getById(id)))
          .then((liste) => liste.whereType<Produit>().toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingIndicator();
        }
        final produits = snapshot.data!;
        if (produits.isEmpty) {
          return const EmptyView(
            message: 'Aucun article disponible',
            subtitle: 'Ces produits ne sont plus en vente.',
            icon: Icons.shopping_cart_outlined,
          );
        }
        final lignes = [
          for (final produit in produits)
            LignePanier(produit: produit, quantite: panier[produit.id] ?? 1),
        ];
        final total = lignes.fold<double>(0, (somme, l) => somme + l.sousTotal);
        final nombreArticles = lignes.fold<int>(0, (somme, l) => somme + l.quantite);
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: lignes.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final ligne = lignes[index];
                  return _CartTile(
                    ligne: ligne,
                    onRemove: () => ref.read(cartProvider.notifier).remove(ligne.produit.id),
                    onQuantiteChangee: (nouvelle) => ref.read(cartProvider.notifier).setQuantite(
                          ligne.produit.id,
                          nouvelle,
                          max: ligne.produit.quantiteDisponible,
                        ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.gray200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total ($nombreArticles article${nombreArticles > 1 ? 's' : ''})',
                                style: AppTypography.bodySmall,
                              ),
                              Text(Formatters.currency(total), style: AppTypography.titleLarge),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'Commander',
                      onPressed: () => _commander(context, ref, lignes),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _commander(BuildContext context, WidgetRef ref, List<LignePanier> lignes) {
    if (ref.read(currentUserProvider) == null) {
      context.push(
        '${AppRoutes.demoAccounts}?from=${Uri.encodeComponent(AppRoutes.cart)}',
      );
      return;
    }
    // Le panier n'est vidé qu'après confirmation réelle de la
    // commande (voir CheckoutNotifier.confirmerAchat) — reculer
    // depuis l'écran de paiement ne doit pas faire perdre la
    // sélection.
    context.push(AppRoutes.checkout, extra: lignes);
  }
}

class _CartTile extends StatelessWidget {
  final LignePanier ligne;
  final VoidCallback onRemove;
  final void Function(int) onQuantiteChangee;

  const _CartTile({
    required this.ligne,
    required this.onRemove,
    required this.onQuantiteChangee,
  });

  @override
  Widget build(BuildContext context) {
    final produit = ligne.produit;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.mdRadius,
            child: SizedBox(
              width: 64,
              height: 64,
              child: produit.photoPrincipale != null
                  ? Image.network(
                      produit.photoPrincipale!.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const EmptyImageIllustration(),
                    )
                  : const EmptyImageIllustration(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.titre,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(ligne.sousTotal),
                  style: AppTypography.titleMedium.copyWith(color: AppColors.violet),
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuantiteStepper(
                  quantite: ligne.quantite,
                  max: produit.quantiteDisponible,
                  onChanged: onQuantiteChangee,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: AppColors.gray500),
            tooltip: 'Retirer du panier',
          ),
        ],
      ),
    );
  }
}

class _QuantiteStepper extends StatelessWidget {
  final int quantite;
  final int max;
  final void Function(int) onChanged;

  const _QuantiteStepper({required this.quantite, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          onTap: quantite > 1 ? () => onChanged(quantite - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$quantite',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium,
          ),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          onTap: quantite < max ? () => onChanged(quantite + 1) : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final actif = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: actif ? AppColors.violetSurface : AppColors.gray100,
          borderRadius: AppRadius.smRadius,
        ),
        child: Icon(icon, size: 16, color: actif ? AppColors.violet : AppColors.gray400),
      ),
    );
  }
}

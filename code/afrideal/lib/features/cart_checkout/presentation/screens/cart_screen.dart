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

/// Panier de l'acheteur : liste des produits mis de côté avant achat.
///
/// Chaque article de la marketplace étant un bien de seconde main
/// unique, le panier ne gère pas de quantité — juste un ensemble de
/// produits, résolus depuis leurs identifiants comme pour les
/// favoris. La commande se passe pour tout le panier en une fois
/// (un seul bouton "Commander" en bas, une seule commande à la fin) —
/// pas une commande séparée par article.
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
        data: (produitIds) {
          if (produitIds.isEmpty) {
            return const EmptyView(
              message: 'Votre panier est vide',
              subtitle: 'Ajoutez un produit depuis sa fiche pour le retrouver ici.',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return _CartList(produitIds: produitIds);
        },
      ),
    );
  }
}

class _CartList extends ConsumerWidget {
  final List<String> produitIds;

  const _CartList({required this.produitIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productRepo = ref.watch(productRepositoryProvider);

    return FutureBuilder<List<Produit>>(
      future: Future.wait(produitIds.map((id) => productRepo.getById(id)))
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
        final total = produits.fold<num>(0, (somme, produit) => somme + produit.prix);
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: produits.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final produit = produits[index];
                  return _CartTile(
                    produit: produit,
                    onRemove: () => ref.read(cartProvider.notifier).remove(produit.id),
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
                                'Total (${produits.length} article${produits.length > 1 ? 's' : ''})',
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
                      onPressed: () => _commander(context, ref, produits),
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

  Future<void> _commander(BuildContext context, WidgetRef ref, List<Produit> produits) async {
    if (ref.read(currentUserProvider) == null) {
      context.push(
        '${AppRoutes.demoAccounts}?from=${Uri.encodeComponent(AppRoutes.cart)}',
      );
      return;
    }
    for (final produit in produits) {
      await ref.read(cartProvider.notifier).remove(produit.id);
    }
    if (context.mounted) {
      context.push(AppRoutes.checkout, extra: produits);
    }
  }
}

class _CartTile extends StatelessWidget {
  final Produit produit;
  final VoidCallback onRemove;

  const _CartTile({
    required this.produit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(produit.titre, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(produit.prix),
                  style: AppTypography.titleMedium.copyWith(color: AppColors.violet),
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

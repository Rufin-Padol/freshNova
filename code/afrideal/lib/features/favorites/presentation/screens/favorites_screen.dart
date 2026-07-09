import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/produit.dart';
import '../../../../shared/widgets/cards/product_card.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../providers/favorites_provider.dart';

/// Grille des produits favoris de l'acheteur. Charge les identifiants
/// favoris puis résout chaque produit correspondant, en filtrant
/// silencieusement les produits qui ne seraient plus disponibles
/// (supprimés ou retirés de la vente entre-temps).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorisAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes favoris')),
      body: favorisAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger vos favoris.',
          onRetry: () => ref.invalidate(favoritesProvider),
        ),
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return const EmptyView(
              message: 'Aucun favori pour le moment',
              subtitle: 'Appuyez sur le cœur d\'un produit pour le retrouver ici.',
              icon: Icons.favorite_border_rounded,
            );
          }
          return _FavoritesGrid(favoriteIds: favoriteIds);
        },
      ),
    );
  }
}

class _FavoritesGrid extends ConsumerWidget {
  final List<String> favoriteIds;

  const _FavoritesGrid({required this.favoriteIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productRepo = ref.watch(productRepositoryProvider);

    return FutureBuilder<List<Produit>>(
      future: Future.wait(favoriteIds.map((id) => productRepo.getById(id)))
          .then((liste) => liste.whereType<Produit>().toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingIndicator();
        }
        final produits = snapshot.data!;
        if (produits.isEmpty) {
          return const EmptyView(
            message: 'Aucun favori disponible',
            subtitle: 'Ces produits ne sont plus en vente.',
            icon: Icons.favorite_border_rounded,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.68,
          ),
          itemCount: produits.length,
          itemBuilder: (context, index) {
            final produit = produits[index];
            return ProductCard(
              titre: produit.titre,
              prix: produit.prix,
              photoUrl: produit.photoPrincipale?.url,
              estFavori: true,
              onFavoriteTap: () => ref.read(favoritesProvider.notifier).toggle(produit.id),
              onTap: () => context.push(
                AppRoutes.productDetail.replaceFirst(':productId', produit.id),
              ),
            );
          },
        );
      },
    );
  }
}

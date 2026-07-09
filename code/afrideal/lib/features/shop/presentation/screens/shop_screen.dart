import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/cards/product_card.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/layout/section_header.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../cart_checkout/providers/cart_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_list_provider.dart';
import '../widgets/category_selector.dart';

/// Écran d'accueil de la boutique pour l'Acheteur.
///
/// Structure fidèle à la maquette : barre de recherche, sélecteur de
/// catégories, puis grille des annonces récentes. Chaque section se
/// recharge indépendamment grâce à Riverpod (changer une catégorie
/// ne relance pas le chargement des catégories elles-mêmes).
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(currentUserProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final produitsAsync = ref.watch(shopProductsProvider);
    final filtres = ref.watch(shopFiltersProvider);
    final favoris = ref.watch(favoritesProvider).valueOrNull ?? [];
    final panier = ref.watch(cartProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () async {
            ref.invalidate(shopProductsProvider);
            ref.invalidate(categoriesProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bonjour', style: AppTypography.bodyMedium),
                              Text(
                                utilisateur?.prenom ?? 'Bienvenue',
                                style: AppTypography.headline,
                              ),
                            ],
                          ),
                          if (utilisateur == null)
                            TextButton(
                              onPressed: () => context.push(AppRoutes.demoAccounts),
                              child: const Text('Se connecter'),
                            )
                          else
                            Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      onPressed: () => context.push(AppRoutes.cart),
                                      icon: const Icon(Icons.shopping_cart_outlined),
                                    ),
                                    if (panier.isNotEmpty)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.violet,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${panier.length}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () => context.push(AppRoutes.notifications),
                                  icon: const Icon(Icons.notifications_outlined),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchField(
                        onChanged: (texte) =>
                            ref.read(shopFiltersProvider.notifier).setRecherche(texte),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      categoriesAsync.when(
                        loading: () => const SizedBox(
                          height: 86,
                          child: AppLoadingIndicator(),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (categories) => CategorySelector(
                          categories: categories,
                          selectedId: filtres.categorieId,
                          onSelect: (id) =>
                              ref.read(shopFiltersProvider.notifier).setCategorie(id),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const SectionHeader(title: 'Annonces récentes'),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              produitsAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoadingIndicator(),
                ),
                error: (_, __) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    message: 'Impossible de charger les produits.',
                    onRetry: () => ref.invalidate(shopProductsProvider),
                  ),
                ),
                data: (produits) {
                  if (produits.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: EmptyView(
                          message: 'Aucun produit trouvé',
                          subtitle: 'Essayez une autre recherche ou catégorie.',
                          icon: Icons.search_off_rounded,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final produit = produits[index];
                          return ProductCard(
                            titre: produit.titre,
                            prix: produit.prix,
                            photoUrl: produit.photoPrincipale?.url,
                            estFavori: favoris.contains(produit.id),
                            onFavoriteTap: () {
                              if (utilisateur == null) {
                                context.push(
                                  '${AppRoutes.demoAccounts}?from=${Uri.encodeComponent(AppRoutes.shop)}',
                                );
                                return;
                              }
                              ref.read(favoritesProvider.notifier).toggle(produit.id);
                            },
                            onTap: () => context.push(
                              AppRoutes.productDetail.replaceFirst(':productId', produit.id),
                            ),
                          );
                        },
                        childCount: produits.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

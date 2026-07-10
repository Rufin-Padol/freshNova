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
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../cart_checkout/providers/cart_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../providers/product_list_provider.dart';

/// Écran de recherche dédié, ouvert depuis la barre de recherche de la
/// boutique (qui ne filtre plus sur place — elle ouvre cet écran,
/// clavier déjà actif, comme un vrai champ de recherche plutôt qu'un
/// simple filtre affiché en haut de liste).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _requete = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(currentUserProvider);
    final produitsAsync = ref.watch(shopProductsProvider);
    final favoris = ref.watch(favoritesProvider).valueOrNull ?? [];
    final panier = ref.watch(cartProvider).valueOrNull ?? {};

    void demanderConnexion() {
      context.push(
        '${AppRoutes.demoAccounts}?from=${Uri.encodeComponent(AppRoutes.search)}',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: AppSearchField(
                      controller: _controller,
                      autofocus: true,
                      hint: 'Rechercher un produit...',
                      onChanged: (v) => setState(() => _requete = v.trim().toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _requete.isEmpty
                  ? const _EtatVide()
                  : produitsAsync.when(
                      loading: () => const AppLoadingIndicator(),
                      error: (_, __) => const ErrorView(
                        message: 'Impossible de charger les produits.',
                      ),
                      data: (produits) {
                        final resultats = produits.where((p) {
                          final texte = '${p.titre} ${p.description}'.toLowerCase();
                          return texte.contains(_requete);
                        }).toList();

                        if (resultats.isEmpty) {
                          return const EmptyView(
                            message: 'Aucun résultat',
                            subtitle: 'Essayez un autre mot-clé.',
                            icon: Icons.search_off_rounded,
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: resultats.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final produit = resultats[index];
                            return ProductCard(
                              titre: produit.titre,
                              prix: produit.prix,
                              photoUrl: produit.photoPrincipale?.url,
                              localisation: produit.localisation,
                              quantiteDisponible: produit.quantiteDisponible,
                              estFavori: favoris.contains(produit.id),
                              onFavoriteTap: () {
                                if (utilisateur == null) {
                                  demanderConnexion();
                                  return;
                                }
                                ref.read(favoritesProvider.notifier).toggle(produit.id);
                              },
                              estDansPanier: panier.containsKey(produit.id),
                              onCartTap: () async {
                                final ajoute = !panier.containsKey(produit.id);
                                await ref
                                    .read(cartProvider.notifier)
                                    .toggle(produit.id, max: produit.quantiteDisponible);
                                if (context.mounted) {
                                  AppSnackbar.showSuccess(
                                    context,
                                    ajoute ? 'Ajouté au panier' : 'Retiré du panier',
                                  );
                                }
                              },
                              onTap: () => context.push(
                                AppRoutes.productDetail.replaceFirst(':productId', produit.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  const _EtatVide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_rounded, color: AppColors.gray300, size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tapez pour rechercher un produit',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

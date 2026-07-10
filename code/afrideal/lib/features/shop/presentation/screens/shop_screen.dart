import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final panier = ref.watch(cartProvider).valueOrNull ?? {};

    void demanderConnexion() {
      context.push(
        '${AppRoutes.demoAccounts}?from=${Uri.encodeComponent(AppRoutes.shop)}',
      );
    }

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
                          Row(
                            children: [
                              // Visible même sans connexion : on peut
                              // ajouter au panier en tant qu'invité, il
                              // faut donc pouvoir voir et ouvrir ce
                              // panier sans être connecté.
                              _TopIconButton(
                                icon: Icons.shopping_cart_outlined,
                                badgeCount: panier.values.fold(0, (a, b) => a + b),
                                onTap: () => context.push(AppRoutes.cart),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              if (utilisateur == null)
                                TextButton(
                                  onPressed: () => context.push(AppRoutes.demoAccounts),
                                  child: const Text('Se connecter'),
                                )
                              else
                                _TopIconButton(
                                  icon: Icons.notifications_outlined,
                                  onTap: () => context.push(AppRoutes.notifications),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: AppSearchField(
                              readOnly: true,
                              onTap: () => context.push(AppRoutes.search),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterButton(
                            tri: filtres.tri,
                            onSelect: (tri) =>
                                ref.read(shopFiltersProvider.notifier).setTri(tri),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _PromoBanner(),
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
                    sliver: SliverList.separated(
                      itemCount: produits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final produit = produits[index];
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

/// Bouton d'action du bandeau supérieur (panier, notifications) —
/// carré arrondi avec ombre douce, badge de compteur optionnel.
class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _TopIconButton({required this.icon, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdRadius,
              boxShadow: AppShadows.card,
            ),
            child: Icon(icon, color: AppColors.gray700, size: 22),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$badgeCount',
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
    );
  }
}

/// Bouton de tri, à côté de la barre de recherche. Ouvre une feuille
/// de choix plutôt qu'un vrai système de filtres multi-critères : la
/// boutique n'a qu'un seul axe de tri pertinent pour l'instant (le
/// prix), pas de note ni de disponibilité par article puisque chaque
/// annonce est un bien unique.
class _FilterButton extends StatelessWidget {
  final ShopTri tri;
  final void Function(ShopTri) onSelect;

  const _FilterButton({required this.tri, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _ouvrirTri(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: tri == ShopTri.recent ? AppColors.surface : AppColors.violet,
          borderRadius: AppRadius.mdRadius,
          boxShadow: AppShadows.card,
        ),
        child: Icon(
          Icons.tune_rounded,
          color: tri == ShopTri.recent ? AppColors.gray700 : AppColors.white,
          size: 22,
        ),
      ),
    );
  }

  void _ouvrirTri(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.xlRadius.topLeft),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trier par', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _OptionTri(
              label: 'Plus récents',
              selected: tri == ShopTri.recent,
              onTap: () => _choisir(sheetContext, ShopTri.recent),
            ),
            _OptionTri(
              label: 'Prix croissant',
              selected: tri == ShopTri.prixCroissant,
              onTap: () => _choisir(sheetContext, ShopTri.prixCroissant),
            ),
            _OptionTri(
              label: 'Prix décroissant',
              selected: tri == ShopTri.prixDecroissant,
              onTap: () => _choisir(sheetContext, ShopTri.prixDecroissant),
            ),
          ],
        ),
      ),
    );
  }

  void _choisir(BuildContext sheetContext, ShopTri choix) {
    onSelect(choix);
    Navigator.of(sheetContext).pop();
  }
}

class _OptionTri extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTri({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTypography.bodyLarge),
      trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.violet) : null,
      onTap: onTap,
    );
  }
}

/// Bandeau promotionnel défilant, en haut de la boutique. Met en
/// avant nos vrais atouts (vérification par agent, paiement à la
/// livraison, couverture nationale) plutôt que des promotions
/// fictives — TrustNova ne fixe pas les prix des annonces, il n'y a
/// donc pas de "réduction" à afficher de façon honnête.
class _PromoBanner extends StatefulWidget {
  const _PromoBanner();

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  static const _slides = [
    (
      illustration: 'assets/illustrations/promo_verified.svg',
      titre: 'Achetez en toute confiance',
      sousTitre: 'Chaque produit est vérifié par un agent TrustNova avant la vente.',
      detail: 'Avant toute mise en vente, un agent TrustNova se déplace chez le '
          'propriétaire pour examiner le produit, vérifier son état réel et '
          'prendre des photos officielles. Aucune annonce n\'est publiée sans '
          'cette vérification.',
    ),
    (
      illustration: 'assets/illustrations/promo_payment.svg',
      titre: 'Payez à la livraison',
      sousTitre: 'Espèces, Orange Money ou MTN Mobile Money — réglez à la réception.',
      detail: 'Rien n\'est débité au moment de la commande. Vous payez uniquement '
          'quand le produit est entre vos mains, en espèces ou par Mobile '
          'Money (Orange Money, MTN MoMo).',
    ),
    (
      illustration: 'assets/illustrations/promo_map.svg',
      titre: 'Partout au Cameroun',
      sousTitre: 'Douala, Yaoundé et au-delà : nous livrons où que vous soyez.',
      detail: 'Notre réseau d\'agents et de livreurs couvre les grandes villes '
          'du Cameroun et s\'étend progressivement. Les annonces de votre '
          'propre ville remontent en priorité dans la boutique.',
    ),
  ];

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ouvrirDetail(BuildContext context, ({String detail, String titre}) slide) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.xlRadius.topLeft),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(slide.titre, style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(slide.detail, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.lgRadius,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slide.titre,
                            style: AppTypography.titleLarge.copyWith(color: AppColors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.sousTitre,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GestureDetector(
                            onTap: () => _ouvrirDetail(
                              context,
                              (titre: slide.titre, detail: slide.detail),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.black,
                                borderRadius: AppRadius.fullRadius,
                              ),
                              child: Text(
                                'En savoir plus',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 130,
                      width: 104,
                      child: SvgPicture.asset(slide.illustration, fit: BoxFit.contain),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            final estActif = index == _page;
            return AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: estActif ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: estActif ? AppColors.violet : AppColors.gray300,
                borderRadius: AppRadius.fullRadius,
              ),
            );
          }),
        ),
      ],
    );
  }
}

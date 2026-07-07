#!/bin/bash
# ============================================================================
# SCRIPT 10 — Écrans d'authentification et Boutique Acheteur
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. Providers de feature :
#        • lib/features/shop/providers/category_provider.dart
#        • lib/features/shop/providers/product_list_provider.dart
#        • lib/features/favorites/providers/favorites_provider.dart
#   2. Écrans d'authentification (remplacent les placeholders) :
#        • EntryChoiceScreen   → écran de bienvenue (logo, accroche,
#          bouton "Découvrir AfriDeal")
#        • DemoAccountsScreen  → sélection du compte de démonstration
#          (choix validé : pas d'OTP, sélection directe par rôle)
#   3. Écrans Acheteur :
#        • ShopScreen          → accueil boutique (recherche,
#          catégories, annonces récentes) — fidèle à la maquette
#        • ProductDetailScreen → fiche produit complète (galerie,
#          vendeur, description, état, bouton Acheter/Contacter)
#
# IMPORTANT : ce script REMPLACE les routes correspondantes dans
# app_router.dart (qui pointaient vers PlaceholderScreen) par les
# vrais écrans. Les autres routes restent en placeholder jusqu'aux
# scripts suivants.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 10_auth_and_shop_screens.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 10 terminé avec succès."
#   Au lancement de l'app, vous verrez maintenant le vrai écran de
#   bienvenue AfriDeal, la sélection de compte démo, puis (en vous
#   connectant comme Acheteur) la vraie boutique avec les produits
#   de démonstration.
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 10/14 : Auth et Boutique Acheteur"
echo "============================================================"

if [ ! -f "lib/core/router/app_router.dart" ]; then
  echo "ERREUR : app_router.dart introuvable. Avez-vous exécuté le script 09 ?"
  exit 1
fi

mkdir -p lib/features/shop/providers
mkdir -p lib/features/shop/presentation/screens
mkdir -p lib/features/shop/presentation/widgets
mkdir -p lib/features/favorites/providers
mkdir -p lib/features/auth/presentation/screens
mkdir -p lib/features/product_detail/presentation/screens
mkdir -p lib/features/product_detail/providers

# ============================================================================
# 1. PROVIDERS — Catégories
# ============================================================================
cat > lib/features/shop/providers/category_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/categorie.dart';

/// Charge la liste des catégories de produits, utilisée par la
/// boutique pour les filtres et par le formulaire de soumission
/// vendeur pour le choix de catégorie.
final categoriesProvider = FutureProvider<List<Categorie>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
});
EOF
echo "→ lib/features/shop/providers/category_provider.dart créé."

# ============================================================================
# 2. PROVIDERS — Liste de produits (boutique)
# ============================================================================
cat > lib/features/shop/providers/product_list_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/produit.dart';

/// État des filtres actifs sur la boutique (catégorie sélectionnée et
/// texte de recherche). Séparé du provider de liste pour que changer
/// un filtre ne recharge que ce qui est nécessaire.
class ShopFilters {
  final String? categorieId;
  final String recherche;

  const ShopFilters({this.categorieId, this.recherche = ''});

  ShopFilters copyWith({String? categorieId, String? recherche, bool clearCategorie = false}) {
    return ShopFilters(
      categorieId: clearCategorie ? null : (categorieId ?? this.categorieId),
      recherche: recherche ?? this.recherche,
    );
  }
}

class ShopFiltersNotifier extends Notifier<ShopFilters> {
  @override
  ShopFilters build() => const ShopFilters();

  void setCategorie(String? categorieId) {
    state = state.copyWith(categorieId: categorieId, clearCategorie: categorieId == null);
  }

  void setRecherche(String texte) {
    state = state.copyWith(recherche: texte);
  }

  void reset() {
    state = const ShopFilters();
  }
}

final shopFiltersProvider = NotifierProvider<ShopFiltersNotifier, ShopFilters>(
  ShopFiltersNotifier.new,
);

/// Liste des produits en vente, recalculée automatiquement à chaque
/// changement de filtre grâce à ref.watch(shopFiltersProvider).
final shopProductsProvider = FutureProvider<List<Produit>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final filtres = ref.watch(shopFiltersProvider);
  return repo.getEnVente(
    categorieId: filtres.categorieId,
    recherche: filtres.recherche.isEmpty ? null : filtres.recherche,
  );
});

/// Détail d'un produit unique, utilisé par la fiche produit.
/// .family permet de paramétrer ce provider par identifiant de
/// produit sans avoir à créer un provider par produit manuellement.
final productDetailProvider = FutureProvider.family<Produit?, String>((ref, productId) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getById(productId);
});
EOF
echo "→ lib/features/shop/providers/product_list_provider.dart créé."

# ============================================================================
# 3. PROVIDERS — Favoris
# ============================================================================
cat > lib/features/favorites/providers/favorites_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/session_provider.dart';

/// Liste des identifiants de produits favoris de l'utilisateur
/// connecté. Utilise AsyncNotifier pour permettre un rechargement
/// explicite après ajout/retrait, avec mise à jour optimiste de
/// l'interface (la liste change immédiatement, sans attendre Hive).
class FavoritesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final utilisateur = ref.watch(currentUserProvider);
    if (utilisateur == null) return [];
    final repo = ref.watch(favoriteRepositoryProvider);
    return repo.getFavoriteProductIds(utilisateur.id);
  }

  Future<void> toggle(String produitId) async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null) return;
    final repo = ref.read(favoriteRepositoryProvider);
    final actuel = state.valueOrNull ?? [];

    if (actuel.contains(produitId)) {
      state = AsyncData(actuel.where((id) => id != produitId).toList());
      await repo.removeFavorite(utilisateur.id, produitId);
    } else {
      state = AsyncData([...actuel, produitId]);
      await repo.addFavorite(utilisateur.id, produitId);
    }
  }

  bool isFavorite(String produitId) {
    return (state.valueOrNull ?? []).contains(produitId);
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<String>>(
  FavoritesNotifier.new,
);
EOF
echo "→ lib/features/favorites/providers/favorites_provider.dart créé."

# ============================================================================
# 4. ÉCRAN — Bienvenue (EntryChoiceScreen)
# ============================================================================
cat > lib/features/auth/presentation/screens/entry_choice_screen.dart << 'EOF'
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
/// Reprend l'identité visuelle AfriDeal validée : dégradé violet-bleu,
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
                  'AfriDeal',
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
                    label: 'Découvrir AfriDeal',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.go(AppRoutes.demoAccounts),
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
EOF
echo "→ lib/features/auth/presentation/screens/entry_choice_screen.dart créé."

# ============================================================================
# 5. ÉCRAN — Sélection de compte démo
# ============================================================================
cat > lib/features/auth/presentation/screens/demo_accounts_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/entities/utilisateur.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../providers/demo_accounts_provider.dart';
import '../../providers/session_provider.dart';

/// Écran de sélection d'un compte de démonstration.
///
/// Conforme au choix validé : en mode local, l'authentification se
/// fait par sélection directe d'un profil (Acheteur, Vendeur, Agent,
/// Admin, Super Admin) plutôt que par saisie d'identifiants ou OTP.
/// Le routeur redirige ensuite automatiquement vers le bon espace
/// applicatif selon le rôle choisi (voir app_router.dart).
class DemoAccountsScreen extends ConsumerWidget {
  const DemoAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(demoAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Choisir un profil')),
      body: comptesAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorView(
          message: 'Impossible de charger les comptes de démonstration.',
          onRetry: () => ref.invalidate(demoAccountsProvider),
        ),
        data: (comptes) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Mode démonstration',
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sélectionnez un profil pour explorer AfriDeal. '
              'Chaque profil donne accès à un espace différent de la plateforme.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            ...comptes.map((compte) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _DemoAccountTile(
                    utilisateur: compte,
                    onTap: () async {
                      await ref.read(sessionProvider.notifier).loginAsDemo(compte);
                      final session = ref.read(sessionProvider);
                      if (context.mounted && session.hasError) {
                        AppSnackbar.showError(context, 'Connexion impossible. Réessayez.');
                      }
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DemoAccountTile extends StatelessWidget {
  final Utilisateur utilisateur;
  final VoidCallback onTap;

  const _DemoAccountTile({required this.utilisateur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            AppAvatar(initiales: utilisateur.initiales, size: 48),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(utilisateur.nomComplet, style: AppTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(_descriptionRole(utilisateur.role), style: AppTypography.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  String _descriptionRole(UserRole role) {
    switch (role) {
      case UserRole.acheteur:
        return 'Parcourir et acheter des produits';
      case UserRole.vendeur:
        return 'Vendre des produits d\'occasion';
      case UserRole.agentTerrain:
        return 'Vérifier et collecter les produits';
      case UserRole.admin:
        return 'Gérer la plateforme';
      case UserRole.superAdmin:
        return 'Administration générale';
    }
  }
}
EOF
echo "→ lib/features/auth/presentation/screens/demo_accounts_screen.dart créé."

# ============================================================================
# 6. WIDGET — Sélecteur de catégorie (utilisé par ShopScreen)
# ============================================================================
cat > lib/features/shop/presentation/widgets/category_selector.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/categorie.dart';

/// Icônes Material associées à chaque catégorie de démonstration.
/// En l'absence d'icônes SVG dédiées par catégorie, ce mapping garde
/// un rendu professionnel et cohérent à travers la boutique.
IconData _iconePourCategorie(String nom) {
  switch (nom) {
    case 'Électronique':
      return Icons.smartphone_rounded;
    case 'Mode':
      return Icons.checkroom_rounded;
    case 'Maison':
      return Icons.chair_rounded;
    case 'Véhicules':
      return Icons.directions_car_rounded;
    default:
      return Icons.category_rounded;
  }
}

/// Rangée horizontale de catégories avec sélection, utilisée en haut
/// de la boutique. Reprend la disposition de la maquette (icône
/// ronde + libellé sous chaque catégorie).
class CategorySelector extends StatelessWidget {
  final List<Categorie> categories;
  final String? selectedId;
  final void Function(String?) onSelect;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, index) {
          final categorie = categories[index];
          final estSelectionne = selectedId == categorie.id;
          return GestureDetector(
            onTap: () => onSelect(estSelectionne ? null : categorie.id),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: estSelectionne ? AppColors.violet : AppColors.violetSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconePourCategorie(categorie.nom),
                    color: estSelectionne ? AppColors.white : AppColors.violet,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(categorie.nom, style: AppTypography.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}
EOF
echo "→ lib/features/shop/presentation/widgets/category_selector.dart créé."

# ============================================================================
# 7. ÉCRAN — Boutique (accueil Acheteur)
# ============================================================================
cat > lib/features/shop/presentation/screens/shop_screen.dart << 'EOF'
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
                                utilisateur?.prenom ?? 'Acheteur',
                                style: AppTypography.headline,
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => context.push(AppRoutes.notifications),
                            icon: const Icon(Icons.notifications_outlined),
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
                            localisation: produit.localisation,
                            photoUrl: produit.photoPrincipale?.url,
                            estFavori: favoris.contains(produit.id),
                            onFavoriteTap: () =>
                                ref.read(favoritesProvider.notifier).toggle(produit.id),
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
EOF
echo "→ lib/features/shop/presentation/screens/shop_screen.dart créé."

# ============================================================================
# 8. ÉCRAN — Fiche produit
# ============================================================================
cat > lib/features/product_detail/presentation/screens/product_detail_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_secondary_button.dart';
import '../../../../shared/widgets/cards/app_avatar.dart';
import '../../../../shared/widgets/cards/info_row.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../../shared/widgets/illustrations/empty_image_illustration.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../shop/providers/product_list_provider.dart';

/// Fiche détaillée d'un produit, accessible aux acheteurs depuis la
/// boutique. Affiche la photo officielle, le vendeur, l'état, la
/// localisation, et la description — y compris les défauts connus
/// affichés de façon transparente, conformément au cahier des charges.
class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitAsync = ref.watch(productDetailProvider(productId));
    final utilisateur = ref.watch(currentUserProvider);
    final estAcheteur = utilisateur?.role == UserRole.acheteur;
    final favoris = ref.watch(favoritesProvider).valueOrNull ?? [];
    final estFavori = favoris.contains(productId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: produitAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Impossible de charger ce produit.',
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (produit) {
          if (produit == null) {
            return const ErrorView(message: 'Ce produit n\'existe plus.');
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.black,
                expandedHeight: 320,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                  ),
                ),
                actions: [
                  if (estAcheteur)
                    IconButton(
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(productId),
                      icon: Icon(
                        estFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: estFavori ? AppColors.danger : AppColors.black,
                      ),
                      style: IconButton.styleFrom(backgroundColor: AppColors.white),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: produit.photoPrincipale != null
                      ? Image.network(
                          produit.photoPrincipale!.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const EmptyImageIllustration(),
                        )
                      : const EmptyImageIllustration(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produit.titre, style: AppTypography.displayMedium),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.currency(produit.prix),
                        style: AppTypography.displayMedium.copyWith(color: AppColors.violet),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgRadius,
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Row(
                          children: [
                            const AppAvatar(initiales: 'V', size: 44),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Vendeur vérifié', style: AppTypography.titleMedium),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded,
                                          size: 16, color: AppColors.blue),
                                    ],
                                  ),
                                  Text(
                                    'Identité et produit vérifiés par AfriDeal',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Description', style: AppTypography.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(produit.description, style: AppTypography.bodyLarge),
                      if (produit.defautsConnus != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warningSurface,
                            borderRadius: AppRadius.mdRadius,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 18, color: AppColors.warning),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  produit.defautsConnus!,
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: AppColors.gray700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: InfoRow(
                              icon: Icons.checkroom_outlined,
                              label: 'État',
                              value: produit.etat.label,
                            ),
                          ),
                          Expanded(
                            child: InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Localisation',
                              value: produit.localisation,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: produitAsync.maybeWhen(
        data: (produit) => produit == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Contacter',
                          icon: Icons.chat_bubble_outline_rounded,
                          onPressed: () => context.push(AppRoutes.messages),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: AppPrimaryButton(
                          label: 'Acheter en sécurité',
                          icon: Icons.shield_outlined,
                          onPressed: () => context.push(AppRoutes.checkout),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        orElse: () => null,
      ),
    );
  }
}
EOF
echo "→ lib/features/product_detail/presentation/screens/product_detail_screen.dart créé."

# ============================================================================
# 9. MISE À JOUR DU ROUTEUR — branchement des vrais écrans
# ============================================================================
echo "→ Mise à jour de app_router.dart pour brancher les nouveaux écrans..."

# Ajout des imports nécessaires juste après les imports existants.
python3 << 'PYEOF'
import re

path = "lib/core/router/app_router.dart"
with open(path, encoding="utf-8") as f:
    content = f.read()

new_imports = (
    "import '../../features/auth/presentation/screens/entry_choice_screen.dart';\n"
    "import '../../features/auth/presentation/screens/demo_accounts_screen.dart';\n"
    "import '../../features/shop/presentation/screens/shop_screen.dart';\n"
    "import '../../features/product_detail/presentation/screens/product_detail_screen.dart';\n"
)

marker = "import 'app_routes.dart';\n"
if marker not in content:
    raise SystemExit("ERREUR : marqueur d'import introuvable dans app_router.dart")
content = content.replace(marker, marker + new_imports, 1)

# Remplace les routes placeholder par les vrais écrans, une par une,
# en s'assurant que chaque remplacement est unique et explicite.
replacements = [
    (
        "GoRoute(\n        path: AppRoutes.entryChoice,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Commencer'),\n      ),",
        "GoRoute(\n        path: AppRoutes.entryChoice,\n        builder: (context, state) => const EntryChoiceScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.demoAccounts,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Comptes de démonstration'),\n      ),",
        "GoRoute(\n        path: AppRoutes.demoAccounts,\n        builder: (context, state) => const DemoAccountsScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.shop,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Boutique'),\n      ),",
        "GoRoute(\n        path: AppRoutes.shop,\n        builder: (context, state) => const ShopScreen(),\n      ),",
    ),
    (
        "GoRoute(\n        path: AppRoutes.productDetail,\n        builder: (context, state) => const PlaceholderScreen(titre: 'Détail produit'),\n      ),",
        "GoRoute(\n        path: AppRoutes.productDetail,\n        builder: (context, state) {\n          final productId = state.pathParameters['productId']!;\n          return ProductDetailScreen(productId: productId);\n        },\n      ),",
    ),
]

for old, new in replacements:
    if old not in content:
        raise SystemExit(f"ERREUR : bloc de route introuvable pour remplacement :\n{old[:80]}...")
    content = content.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("app_router.dart mis à jour avec succès (4 routes branchées).")
PYEOF

echo ""
echo "============================================================"
echo "  ✔ Script 10 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • Providers : catégories, liste produits avec filtres,"
echo "    détail produit (.family), favoris (AsyncNotifier)."
echo "  • EntryChoiceScreen : écran de bienvenue AfriDeal (dégradé"
echo "    violet-bleu, illustration bouclier de confiance)."
echo "  • DemoAccountsScreen : sélection de profil de démonstration."
echo "  • ShopScreen : boutique complète (recherche, catégories,"
echo "    grille de produits, favoris, pull-to-refresh)."
echo "  • ProductDetailScreen : fiche produit complète (galerie,"
echo "    vendeur vérifié, description, défauts connus, actions)."
echo "  • app_router.dart : 4 routes connectées aux vrais écrans."
echo ""
echo "TESTEZ DÈS MAINTENANT :"
echo "  flutter run"
echo "  Puis choisissez le profil 'Marie Mballa' (Acheteur) pour voir"
echo "  la boutique avec les produits de démonstration."
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 11 : panier,"
echo "  paiement, suivi de commandes et favoris — pour compléter"
echo "  entièrement le parcours Acheteur."
echo ""

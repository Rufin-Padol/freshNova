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

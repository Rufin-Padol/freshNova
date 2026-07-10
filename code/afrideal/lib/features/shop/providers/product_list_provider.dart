import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/produit.dart';
import '../../auth/providers/session_provider.dart';

/// Ordre de tri des annonces dans la boutique.
enum ShopTri { recent, prixCroissant, prixDecroissant }

/// État des filtres actifs sur la boutique (catégorie sélectionnée,
/// texte de recherche, tri). Séparé du provider de liste pour que
/// changer un filtre ne recharge que ce qui est nécessaire.
class ShopFilters {
  final String? categorieId;
  final String recherche;
  final ShopTri tri;

  const ShopFilters({this.categorieId, this.recherche = '', this.tri = ShopTri.recent});

  ShopFilters copyWith({
    String? categorieId,
    String? recherche,
    ShopTri? tri,
    bool clearCategorie = false,
  }) {
    return ShopFilters(
      categorieId: clearCategorie ? null : (categorieId ?? this.categorieId),
      recherche: recherche ?? this.recherche,
      tri: tri ?? this.tri,
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

  void setTri(ShopTri tri) {
    state = state.copyWith(tri: tri);
  }

  void reset() {
    state = const ShopFilters();
  }
}

final shopFiltersProvider = NotifierProvider<ShopFiltersNotifier, ShopFilters>(
  ShopFiltersNotifier.new,
);

/// Liste des produits en vente, recalculée automatiquement à chaque
/// changement de filtre grâce à ref.watch(shopFiltersProvider). Le tri
/// se fait côté client : aucune annonce supplémentaire n'est chargée,
/// on réordonne simplement la liste déjà récupérée.
///
/// Par défaut (tri "récents"), les annonces situées dans la même
/// ville que l'acheteur remontent en premier — un signal simple et
/// honnête (basé sur la ville renseignée à l'inscription) plutôt
/// qu'un filtre strict qui masquerait les autres annonces. Un tri prix
/// explicite reste un tri prix pur : on ne réordonne pas un choix
/// explicite de l'utilisateur.
final shopProductsProvider = FutureProvider<List<Produit>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final filtres = ref.watch(shopFiltersProvider);
  final utilisateur = ref.watch(currentUserProvider);
  final produits = await repo.getEnVente(
    categorieId: filtres.categorieId,
    recherche: filtres.recherche.isEmpty ? null : filtres.recherche,
  );
  final tries = [...produits];
  final villeUtilisateur = utilisateur?.ville?.trim().toLowerCase();
  bool memeVille(Produit p) =>
      villeUtilisateur != null &&
      villeUtilisateur.isNotEmpty &&
      p.localisation.toLowerCase().contains(villeUtilisateur);

  switch (filtres.tri) {
    case ShopTri.recent:
      tries.sort((a, b) {
        if (villeUtilisateur != null) {
          final prioriteA = memeVille(a) ? 0 : 1;
          final prioriteB = memeVille(b) ? 0 : 1;
          if (prioriteA != prioriteB) return prioriteA.compareTo(prioriteB);
        }
        return b.dateCreation.compareTo(a.dateCreation);
      });
    case ShopTri.prixCroissant:
      tries.sort((a, b) => a.prix.compareTo(b.prix));
    case ShopTri.prixDecroissant:
      tries.sort((a, b) => b.prix.compareTo(a.prix));
  }
  return tries;
});

/// Détail d'un produit unique, utilisé par la fiche produit.
/// .family permet de paramétrer ce provider par identifiant de
/// produit sans avoir à créer un provider par produit manuellement.
final productDetailProvider = FutureProvider.family<Produit?, String>((ref, productId) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getById(productId);
});

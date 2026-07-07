/// Gestion des favoris. Volontairement simple (juste une liste
/// d'identifiants de produits par utilisateur), sans entité dédiée,
/// car aucune donnée supplémentaire n'est nécessaire au-delà du lien
/// utilisateur-produit.
abstract class IFavoriteRepository {
  Future<List<String>> getFavoriteProductIds(String userId);
  Future<void> addFavorite(String userId, String produitId);
  Future<void> removeFavorite(String userId, String produitId);
  Future<bool> isFavorite(String userId, String produitId);
}

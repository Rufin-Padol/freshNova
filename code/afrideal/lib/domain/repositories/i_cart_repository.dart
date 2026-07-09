/// Gestion du panier. Volontairement simple (juste une liste
/// d'identifiants de produits par utilisateur), comme les favoris :
/// chaque produit de la marketplace est un article unique de seconde
/// main, donc aucune notion de quantité n'a de sens ici.
abstract class ICartRepository {
  Future<List<String>> getCartProductIds(String userId);
  Future<void> addToCart(String userId, String produitId);
  Future<void> removeFromCart(String userId, String produitId);
  Future<bool> isInCart(String userId, String produitId);
}

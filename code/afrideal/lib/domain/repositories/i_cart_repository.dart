/// Gestion du panier — une entrée par produit avec sa quantité
/// commandée (un propriétaire peut avoir plusieurs exemplaires d'un
/// même bien, une annonce n'est donc pas toujours un article unique).
abstract class ICartRepository {
  /// Contenu du panier : identifiant de produit -> quantité voulue.
  Future<Map<String, int>> getCartItems(String userId);

  /// Fixe la quantité d'un produit dans le panier. Une quantité <= 0
  /// retire le produit du panier.
  Future<void> setQuantite(String userId, String produitId, int quantite);
}

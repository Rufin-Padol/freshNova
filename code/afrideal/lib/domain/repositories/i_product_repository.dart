import '../entities/produit.dart';
import '../enums/product_status.dart';

/// Contrat de gestion des produits, indépendant du mode (local ou API).
abstract class IProductRepository {
  Future<List<Produit>> getAll();
  Future<Produit?> getById(String id);

  /// Produits affichables dans la boutique (statut "En vente"),
  /// avec filtres optionnels par catégorie et recherche texte.
  Future<List<Produit>> getEnVente({String? categorieId, String? recherche});

  Future<List<Produit>> getByVendeur(String vendeurId);
  Future<List<Produit>> getByAgent(String agentId);
  Future<List<Produit>> getByStatut(ProductStatus statut);

  Future<void> save(Produit produit);
  Future<void> updateStatut(String produitId, ProductStatus nouveauStatut);
  Future<void> delete(String id);
}

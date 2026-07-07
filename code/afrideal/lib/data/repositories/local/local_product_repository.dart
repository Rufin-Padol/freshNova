import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/repositories/i_product_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/produit_model.dart';

class LocalProductRepository implements IProductRepository {
  final LocalJsonStore<ProduitModel> _store = LocalJsonStore<ProduitModel>(
    boxName: StorageKeys.productsBox,
    toJson: (m) => m.toJson(),
    fromJson: ProduitModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Produit>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Produit?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Produit>> getEnVente({String? categorieId, String? recherche}) async {
    final all = await getAll();
    return all.where((p) {
      final estEnVente = p.statut == ProductStatus.enVente;
      final matchCategorie = categorieId == null || p.categorieId == categorieId;
      final matchRecherche = recherche == null ||
          recherche.isEmpty ||
          p.titre.toLowerCase().contains(recherche.toLowerCase());
      return estEnVente && matchCategorie && matchRecherche;
    }).toList();
  }

  @override
  Future<List<Produit>> getByVendeur(String vendeurId) async {
    final all = await getAll();
    return all.where((p) => p.vendeurId == vendeurId).toList();
  }

  @override
  Future<List<Produit>> getByAgent(String agentId) async {
    final all = await getAll();
    return all.where((p) => p.agentId == agentId).toList();
  }

  @override
  Future<List<Produit>> getByStatut(ProductStatus statut) async {
    final all = await getAll();
    return all.where((p) => p.statut == statut).toList();
  }

  @override
  Future<void> save(Produit produit) async {
    await _store.save(ProduitModel.fromEntity(produit));
  }

  @override
  Future<void> updateStatut(String produitId, ProductStatus nouveauStatut) async {
    final existant = await getById(produitId);
    if (existant == null) return;
    await save(existant.copyWith(statut: nouveauStatut));
  }

  @override
  Future<void> delete(String id) async {
    await _store.delete(id);
  }
}

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/demande_vendeur.dart';
import '../../../domain/repositories/i_seller_request_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/demande_vendeur_model.dart';

class LocalSellerRequestRepository implements ISellerRequestRepository {
  final LocalJsonStore<DemandeVendeurModel> _store =
      LocalJsonStore<DemandeVendeurModel>(
    boxName: StorageKeys.sellerRequestsBox,
    toJson: (m) => m.toJson(),
    fromJson: DemandeVendeurModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<DemandeVendeur>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<DemandeVendeur?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<DemandeVendeur>> getByVendeur(String vendeurId) async {
    final all = await getAll();
    return all.where((d) => d.vendeurId == vendeurId).toList();
  }

  @override
  Future<void> save(DemandeVendeur demande) async {
    await _store.save(DemandeVendeurModel.fromEntity(demande));
  }

  @override
  Future<void> delete(String id) async {
    await _store.delete(id);
  }
}

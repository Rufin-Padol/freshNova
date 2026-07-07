import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/proprietaire.dart';
import '../../../domain/repositories/i_proprietaire_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/proprietaire_model.dart';

class LocalProprietaireRepository implements IProprietaireRepository {
  final LocalJsonStore<ProprietaireModel> _store = LocalJsonStore<ProprietaireModel>(
    boxName: StorageKeys.proprietairesBox,
    toJson: (m) => m.toJson(),
    fromJson: ProprietaireModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Proprietaire>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Proprietaire?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(Proprietaire proprietaire) async {
    await _store.save(ProprietaireModel.fromEntity(proprietaire));
  }
}

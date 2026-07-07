import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/litige.dart';
import '../../../domain/repositories/i_dispute_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/litige_model.dart';

class LocalDisputeRepository implements IDisputeRepository {
  final LocalJsonStore<LitigeModel> _store = LocalJsonStore<LitigeModel>(
    boxName: StorageKeys.disputesBox,
    toJson: (m) => m.toJson(),
    fromJson: LitigeModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Litige>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Litige?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(Litige litige) async {
    await _store.save(LitigeModel.fromEntity(litige));
  }
}

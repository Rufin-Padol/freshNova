import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/mission.dart';
import '../../../domain/repositories/i_mission_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/mission_model.dart';

class LocalMissionRepository implements IMissionRepository {
  final LocalJsonStore<MissionModel> _store = LocalJsonStore<MissionModel>(
    boxName: StorageKeys.missionsBox,
    toJson: (m) => m.toJson(),
    fromJson: MissionModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Mission>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Mission?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Mission>> getByAgent(String agentId) async {
    final all = await getAll();
    return all.where((m) => m.agentId == agentId).toList();
  }

  @override
  Future<void> save(Mission mission) async {
    await _store.save(MissionModel.fromEntity(mission));
  }
}

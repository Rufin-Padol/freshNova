import '../entities/mission.dart';

abstract class IMissionRepository {
  Future<List<Mission>> getAll();
  Future<Mission?> getById(String id);
  Future<List<Mission>> getByAgent(String agentId);
  Future<void> save(Mission mission);
}

import '../entities/litige.dart';

abstract class IDisputeRepository {
  Future<List<Litige>> getAll();
  Future<Litige?> getById(String id);
  Future<void> save(Litige litige);
}

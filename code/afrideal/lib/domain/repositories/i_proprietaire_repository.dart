import '../entities/proprietaire.dart';

abstract class IProprietaireRepository {
  Future<List<Proprietaire>> getAll();
  Future<Proprietaire?> getById(String id);
  Future<void> save(Proprietaire proprietaire);
}

import '../entities/categorie.dart';

abstract class ICategoryRepository {
  Future<List<Categorie>> getAll();
  Future<void> save(Categorie categorie);
  Future<void> delete(String id);
}

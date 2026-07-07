import '../../../domain/entities/categorie.dart';
import '../../../domain/repositories/i_category_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/categorie_model.dart';

class LocalCategoryRepository implements ICategoryRepository {
  final LocalJsonStore<CategorieModel> _store = LocalJsonStore<CategorieModel>(
    boxName: 'categories_box',
    toJson: (m) => m.toJson(),
    fromJson: CategorieModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Categorie>> getAll() async {
    final all = await _store.getAll();
    final entities = all.map((m) => m.toEntity()).toList();
    entities.sort((a, b) => a.ordreAffichage.compareTo(b.ordreAffichage));
    return entities;
  }

  @override
  Future<void> save(Categorie categorie) async {
    await _store.save(CategorieModel.fromEntity(categorie));
  }

  @override
  Future<void> delete(String id) async {
    await _store.delete(id);
  }
}

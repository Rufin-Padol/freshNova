import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/enums/user_role.dart';
import '../../../domain/repositories/i_user_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/utilisateur_model.dart';

class LocalUserRepository implements IUserRepository {
  final LocalJsonStore<UtilisateurModel> _store = LocalJsonStore<UtilisateurModel>(
    boxName: StorageKeys.usersBox,
    toJson: (m) => m.toJson(),
    fromJson: UtilisateurModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Utilisateur>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Utilisateur?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Utilisateur>> getByRole(UserRole role) async {
    final all = await getAll();
    return all.where((u) => u.role == role).toList();
  }

  @override
  Future<void> save(Utilisateur utilisateur) async {
    await _store.save(UtilisateurModel.fromEntity(utilisateur));
  }

  @override
  Future<void> toggleActif(String userId, bool estActif) async {
    final existant = await getById(userId);
    if (existant == null) return;
    await save(existant.copyWith(estActif: estActif));
  }
}

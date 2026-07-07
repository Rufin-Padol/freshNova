import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/utilisateur_model.dart';

/// Implémentation locale de l'authentification, basée sur Hive.
///
/// Les mots de passe ne sont jamais comparés en clair : on compare
/// leur hash SHA-256, exactement comme le ferait un futur backend.
/// Cela permet de garder un code de comparaison identique, qu'on soit
/// en mode local ou en mode API.
class LocalAuthRepository implements IAuthRepository {
  final LocalJsonStore<UtilisateurModel> _store;
  final LocalJsonStore<String> _sessionStore;

  LocalAuthRepository()
      : _store = LocalJsonStore<UtilisateurModel>(
          boxName: StorageKeys.usersBox,
          toJson: (m) => m.toJson(),
          fromJson: UtilisateurModel.fromJson,
          idOf: (m) => m.id,
        ),
        _sessionStore = LocalJsonStore<String>(
          boxName: StorageKeys.sessionBox,
          toJson: (s) => {'value': s},
          fromJson: (json) => json['value'] as String,
          idOf: (s) => StorageKeys.secureCurrentUserIdKey,
        );

  static String hashPassword(String motDePasse) {
    final bytes = utf8.encode(motDePasse);
    return sha256.convert(bytes).toString();
  }

  @override
  Future<Utilisateur?> login({
    required String telephone,
    required String motDePasse,
  }) async {
    final tousLesUtilisateurs = await _store.getAll();
    final hash = hashPassword(motDePasse);

    UtilisateurModel? trouve;
    for (final u in tousLesUtilisateurs) {
      if (u.telephone == telephone && u.motDePasseHash == hash) {
        trouve = u;
        break;
      }
    }

    if (trouve == null) {
      throw const AuthException('Numéro ou mot de passe incorrect.');
    }

    await _sessionStore.save(trouve.id);
    return trouve.toEntity();
  }

  @override
  Future<Utilisateur> register(Utilisateur utilisateur, String motDePasse) async {
    final existants = await _store.getAll();
    final dejaUtilise = existants.any((u) => u.telephone == utilisateur.telephone);
    if (dejaUtilise) {
      throw const BusinessRuleException('Ce numéro est déjà utilisé.');
    }

    final model = UtilisateurModel.fromEntity(
      utilisateur.copyWith(motDePasseHash: hashPassword(motDePasse)),
    );
    await _store.save(model);
    await _sessionStore.save(model.id);
    return model.toEntity();
  }

  @override
  Future<void> logout() async {
    await _sessionStore.delete(StorageKeys.secureCurrentUserIdKey);
  }

  @override
  Future<Utilisateur?> getCurrentUser() async {
    final userId = await _sessionStore.getById(StorageKeys.secureCurrentUserIdKey);
    if (userId == null) return null;
    final model = await _store.getById(userId);
    return model?.toEntity();
  }

  @override
  Future<List<Utilisateur>> getDemoAccounts() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  /// Connecte directement un compte de démonstration par son
  /// identifiant, sans vérification de mot de passe. Utilisé
  /// exclusivement par l'écran de sélection de compte démo.
  @override
  Future<Utilisateur?> loginAsDemoAccount(String userId) async {
    final model = await _store.getById(userId);
    if (model == null) return null;
    await _sessionStore.save(model.id);
    return model.toEntity();
  }
}

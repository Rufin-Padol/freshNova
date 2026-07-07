import '../entities/utilisateur.dart';
import '../enums/user_role.dart';

/// Gestion des utilisateurs (hors authentification), utilisée
/// principalement par les écrans Admin / Super Admin pour lister,
/// activer/désactiver des comptes, et par les écrans qui ont besoin
/// d'afficher les informations d'un autre utilisateur (ex: nom du
/// vendeur sur une fiche produit).
abstract class IUserRepository {
  Future<List<Utilisateur>> getAll();
  Future<Utilisateur?> getById(String id);
  Future<List<Utilisateur>> getByRole(UserRole role);
  Future<void> save(Utilisateur utilisateur);
  Future<void> toggleActif(String userId, bool estActif);
}

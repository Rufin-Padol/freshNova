import '../entities/demande_vendeur.dart';

abstract class ISellerRequestRepository {
  Future<List<DemandeVendeur>> getAll();
  Future<DemandeVendeur?> getById(String id);
  Future<List<DemandeVendeur>> getByVendeur(String vendeurId);
  Future<void> save(DemandeVendeur demande);
  Future<void> delete(String id);
}

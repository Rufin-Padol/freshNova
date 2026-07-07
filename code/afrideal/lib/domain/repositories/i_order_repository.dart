import '../entities/commande.dart';
import '../enums/order_status.dart';

abstract class IOrderRepository {
  Future<List<Commande>> getAll();
  Future<Commande?> getById(String id);
  Future<List<Commande>> getByAcheteur(String acheteurId);
  Future<void> save(Commande commande);
  Future<void> updateStatut(String commandeId, OrderStatus nouveauStatut);
}

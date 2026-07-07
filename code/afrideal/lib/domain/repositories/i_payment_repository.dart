import '../entities/paiement.dart';

abstract class IPaymentRepository {
  Future<List<Paiement>> getByCommande(String commandeId);
  Future<void> save(Paiement paiement);
}

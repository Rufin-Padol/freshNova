import '../../../domain/entities/paiement.dart';
import '../../../domain/repositories/i_payment_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/paiement_model.dart';

class LocalPaymentRepository implements IPaymentRepository {
  final LocalJsonStore<PaiementModel> _store = LocalJsonStore<PaiementModel>(
    boxName: 'payments_box',
    toJson: (m) => m.toJson(),
    fromJson: PaiementModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Paiement>> getByCommande(String commandeId) async {
    final all = await _store.getAll();
    return all
        .where((m) => m.commandeId == commandeId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<void> save(Paiement paiement) async {
    await _store.save(PaiementModel.fromEntity(paiement));
  }
}

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/repositories/i_order_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/commande_model.dart';

class LocalOrderRepository implements IOrderRepository {
  final LocalJsonStore<CommandeModel> _store = LocalJsonStore<CommandeModel>(
    boxName: StorageKeys.ordersBox,
    toJson: (m) => m.toJson(),
    fromJson: CommandeModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Commande>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Commande?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Commande>> getByAcheteur(String acheteurId) async {
    final all = await getAll();
    return all.where((c) => c.acheteurId == acheteurId).toList();
  }

  @override
  Future<void> save(Commande commande) async {
    await _store.save(CommandeModel.fromEntity(commande));
  }

  @override
  Future<void> updateStatut(String commandeId, OrderStatus nouveauStatut) async {
    final existant = await getById(commandeId);
    if (existant == null) return;
    await save(existant.copyWith(statut: nouveauStatut));
  }
}

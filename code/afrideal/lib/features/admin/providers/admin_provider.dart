import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/enums/user_role.dart';

final allProductsAdminProvider = FutureProvider<List<Produit>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final all = await repo.getAll();
  all.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
  return all;
});

final allUsersAdminProvider = FutureProvider<List<Utilisateur>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getAll();
});

final agentsAdminProvider = FutureProvider<List<Utilisateur>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getByRole(UserRole.agentTerrain);
});

/// Actions admin sur les produits (changement de statut).
class AdminProductNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> changerStatut(String produitId, ProductStatus statut) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.updateStatut(produitId, statut);
    ref.invalidate(allProductsAdminProvider);
  }
}

final adminProductNotifierProvider =
    NotifierProvider<AdminProductNotifier, void>(AdminProductNotifier.new);

/// Actions admin sur les utilisateurs (activer/désactiver).
class AdminUserNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleActif(String userId, bool estActif) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.toggleActif(userId, estActif);
    ref.invalidate(allUsersAdminProvider);
  }
}

final adminUserNotifierProvider =
    NotifierProvider<AdminUserNotifier, void>(AdminUserNotifier.new);

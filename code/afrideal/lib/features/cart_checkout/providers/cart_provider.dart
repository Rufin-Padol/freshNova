import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/session_provider.dart';

/// Liste des identifiants de produits présents dans le panier de
/// l'utilisateur connecté. Même logique que FavoritesNotifier : mise
/// à jour optimiste de l'interface, persistée ensuite via Hive.
class CartNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final utilisateur = ref.watch(currentUserProvider);
    if (utilisateur == null) return [];
    final repo = ref.watch(cartRepositoryProvider);
    return repo.getCartProductIds(utilisateur.id);
  }

  Future<void> add(String produitId) async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null) return;
    final repo = ref.read(cartRepositoryProvider);
    final actuel = state.valueOrNull ?? [];
    if (!actuel.contains(produitId)) {
      state = AsyncData([...actuel, produitId]);
      await repo.addToCart(utilisateur.id, produitId);
    }
  }

  Future<void> remove(String produitId) async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null) return;
    final repo = ref.read(cartRepositoryProvider);
    final actuel = state.valueOrNull ?? [];
    state = AsyncData(actuel.where((id) => id != produitId).toList());
    await repo.removeFromCart(utilisateur.id, produitId);
  }

  Future<void> toggle(String produitId) async {
    final actuel = state.valueOrNull ?? [];
    if (actuel.contains(produitId)) {
      await remove(produitId);
    } else {
      await add(produitId);
    }
  }

  bool isInCart(String produitId) {
    return (state.valueOrNull ?? []).contains(produitId);
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<String>>(
  CartNotifier.new,
);

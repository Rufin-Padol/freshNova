import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/session_provider.dart';

/// Liste des identifiants de produits favoris de l'utilisateur
/// connecté. Utilise AsyncNotifier pour permettre un rechargement
/// explicite après ajout/retrait, avec mise à jour optimiste de
/// l'interface (la liste change immédiatement, sans attendre Hive).
class FavoritesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final utilisateur = ref.watch(currentUserProvider);
    if (utilisateur == null) return [];
    final repo = ref.watch(favoriteRepositoryProvider);
    return repo.getFavoriteProductIds(utilisateur.id);
  }

  Future<void> toggle(String produitId) async {
    final utilisateur = ref.read(currentUserProvider);
    if (utilisateur == null) return;
    final repo = ref.read(favoriteRepositoryProvider);
    final actuel = state.valueOrNull ?? [];

    if (actuel.contains(produitId)) {
      state = AsyncData(actuel.where((id) => id != produitId).toList());
      await repo.removeFavorite(utilisateur.id, produitId);
    } else {
      state = AsyncData([...actuel, produitId]);
      await repo.addFavorite(utilisateur.id, produitId);
    }
  }

  bool isFavorite(String produitId) {
    return (state.valueOrNull ?? []).contains(produitId);
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<String>>(
  FavoritesNotifier.new,
);

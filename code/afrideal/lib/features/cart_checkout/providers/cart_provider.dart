import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/session_provider.dart';

/// Clé utilisée pour le panier d'un visiteur non connecté. Ajouter un
/// produit au panier ne nécessite pas de compte — seule la commande
/// (checkout) exige une connexion — donc le panier doit exister même
/// sans utilisateur identifié.
const _cleInvite = 'guest';

/// Liste des identifiants de produits présents dans le panier de
/// l'utilisateur courant (connecté, ou invité via [_cleInvite]). Même
/// logique que FavoritesNotifier : mise à jour optimiste de
/// l'interface, persistée ensuite via Hive.
class CartNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final utilisateur = ref.watch(currentUserProvider);
    final repo = ref.watch(cartRepositoryProvider);
    return repo.getCartProductIds(utilisateur?.id ?? _cleInvite);
  }

  Future<void> add(String produitId) async {
    final cle = ref.read(currentUserProvider)?.id ?? _cleInvite;
    final repo = ref.read(cartRepositoryProvider);
    final actuel = state.valueOrNull ?? [];
    if (!actuel.contains(produitId)) {
      state = AsyncData([...actuel, produitId]);
      await repo.addToCart(cle, produitId);
    }
  }

  Future<void> remove(String produitId) async {
    final cle = ref.read(currentUserProvider)?.id ?? _cleInvite;
    final repo = ref.read(cartRepositoryProvider);
    final actuel = state.valueOrNull ?? [];
    state = AsyncData(actuel.where((id) => id != produitId).toList());
    await repo.removeFromCart(cle, produitId);
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

  /// Transfère le panier "invité" vers le compte qui vient de se
  /// connecter ou de s'inscrire, pour qu'un visiteur ne perde pas sa
  /// sélection au moment où la connexion devient obligatoire (à la
  /// commande). Appelé par SessionNotifier après une connexion réussie.
  Future<void> migrerVersUtilisateur(String utilisateurId) async {
    final repo = ref.read(cartRepositoryProvider);
    final idsInvite = await repo.getCartProductIds(_cleInvite);
    if (idsInvite.isEmpty) return;
    for (final id in idsInvite) {
      await repo.addToCart(utilisateurId, id);
      await repo.removeFromCart(_cleInvite, id);
    }
    state = AsyncData(await repo.getCartProductIds(utilisateurId));
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<String>>(
  CartNotifier.new,
);

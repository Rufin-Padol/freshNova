import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/session_provider.dart';

/// Clé utilisée pour le panier d'un visiteur non connecté. Ajouter un
/// produit au panier ne nécessite pas de compte — seule la commande
/// (checkout) exige une connexion — donc le panier doit exister même
/// sans utilisateur identifié.
const _cleInvite = 'guest';

/// Contenu du panier de l'utilisateur courant (connecté, ou invité via
/// [_cleInvite]) : identifiant de produit -> quantité voulue. Un
/// propriétaire pouvant avoir plusieurs exemplaires d'un même bien, le
/// panier retient une quantité par produit plutôt qu'une simple
/// présence/absence. Mise à jour optimiste de l'interface, persistée
/// ensuite via Hive (même principe que FavoritesNotifier).
class CartNotifier extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() async {
    final utilisateur = ref.watch(currentUserProvider);
    final repo = ref.watch(cartRepositoryProvider);
    return repo.getCartItems(utilisateur?.id ?? _cleInvite);
  }

  Future<void> _setQuantite(String produitId, int quantite) async {
    final cle = ref.read(currentUserProvider)?.id ?? _cleInvite;
    final repo = ref.read(cartRepositoryProvider);
    final actuel = Map<String, int>.from(state.valueOrNull ?? {});
    if (quantite <= 0) {
      actuel.remove(produitId);
    } else {
      actuel[produitId] = quantite;
    }
    state = AsyncData(actuel);
    await repo.setQuantite(cle, produitId, quantite);
  }

  /// Ajoute une unité du produit (jusqu'à [max] s'il est déjà dans le
  /// panier). Utilisé par le bouton "Ajouter au panier" simple des
  /// cartes produit — le réglage fin de quantité se fait dans l'écran
  /// du panier.
  Future<void> add(String produitId, {int max = 1}) async {
    final actuelle = (state.valueOrNull ?? {})[produitId] ?? 0;
    if (actuelle >= max) return;
    await _setQuantite(produitId, actuelle + 1);
  }

  Future<void> remove(String produitId) => _setQuantite(produitId, 0);

  Future<void> setQuantite(String produitId, int quantite, {required int max}) {
    return _setQuantite(produitId, quantite.clamp(0, max));
  }

  Future<void> toggle(String produitId, {int max = 1}) async {
    final actuel = state.valueOrNull ?? {};
    if (actuel.containsKey(produitId)) {
      await remove(produitId);
    } else {
      await add(produitId, max: max);
    }
  }

  bool isInCart(String produitId) {
    return (state.valueOrNull ?? {}).containsKey(produitId);
  }

  /// Transfère le panier "invité" vers le compte qui vient de se
  /// connecter ou de s'inscrire, pour qu'un visiteur ne perde pas sa
  /// sélection au moment où la connexion devient obligatoire (à la
  /// commande). Les quantités s'additionnent en cas de doublon.
  /// Appelé par SessionNotifier après une connexion réussie.
  Future<void> migrerVersUtilisateur(String utilisateurId) async {
    final repo = ref.read(cartRepositoryProvider);
    final panierInvite = await repo.getCartItems(_cleInvite);
    if (panierInvite.isEmpty) return;
    final panierUtilisateur = await repo.getCartItems(utilisateurId);
    for (final entry in panierInvite.entries) {
      final total = (panierUtilisateur[entry.key] ?? 0) + entry.value;
      await repo.setQuantite(utilisateurId, entry.key, total);
      await repo.setQuantite(_cleInvite, entry.key, 0);
    }
    state = AsyncData(await repo.getCartItems(utilisateurId));
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, Map<String, int>>(
  CartNotifier.new,
);

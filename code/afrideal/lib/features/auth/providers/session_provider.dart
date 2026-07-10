import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../cart_checkout/providers/cart_provider.dart';

/// État de la session utilisateur. Volontairement simple (un seul
/// champ nullable) : null signifie "personne n'est connecté".
typedef SessionState = Utilisateur?;

/// Gère la connexion, la déconnexion, et la restauration automatique
/// de la session au démarrage de l'application.
///
/// Utilise AsyncNotifier (et non Notifier simple) car la restauration
/// de session au démarrage nécessite une lecture asynchrone du
/// stockage local (ou, plus tard, une vérification de token auprès
/// de l'API), donc l'état initial n'est jamais immédiatement
/// disponible de façon synchrone.
class SessionNotifier extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final authRepo = ref.watch(authRepositoryProvider);
    return authRepo.getCurrentUser();
  }

  Future<void> login({required String telephone, required String motDePasse}) async {
    state = const AsyncLoading();
    final authRepo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(
      () => authRepo.login(telephone: telephone, motDePasse: motDePasse),
    );
    await _migrerPanierInvite();
  }

  /// Crée un nouveau compte et connecte immédiatement la session sur
  /// ce compte (contrairement à creerCompteSansConnexion, réservé au
  /// Super Admin créant un compte Admin pour quelqu'un d'autre).
  Future<void> register(Utilisateur utilisateur, String motDePasse) async {
    state = const AsyncLoading();
    final authRepo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(
      () => authRepo.register(utilisateur, motDePasse),
    );
    await _migrerPanierInvite();
  }

  /// Connecte directement un compte de démonstration, sans mot de
  /// passe, conformément au choix validé pour le mode local.
  Future<void> loginAsDemo(Utilisateur compteDemo) async {
    state = const AsyncLoading();
    final authRepo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(
      () => authRepo.loginAsDemoAccount(compteDemo.id),
    );
    await _migrerPanierInvite();
  }

  /// Un visiteur peut ajouter des produits au panier sans être
  /// connecté (seule la commande exige un compte) — au moment où il
  /// se connecte, on transfère ce panier "invité" vers son compte pour
  /// qu'il ne perde pas sa sélection.
  Future<void> _migrerPanierInvite() async {
    final utilisateur = state.valueOrNull;
    if (utilisateur == null) return;
    await ref.read(cartProvider.notifier).migrerVersUtilisateur(utilisateur.id);
  }

  Future<void> logout() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();
    state = const AsyncData(null);
  }

  Future<void> refresh() async {
    final authRepo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(() => authRepo.getCurrentUser());
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// Raccourci pratique pour accéder à l'utilisateur connecté sans
/// gérer manuellement les états AsyncLoading/AsyncError à chaque
/// utilisation. Retourne null tant que la session n'est pas
/// disponible (chargement, erreur, ou personne connecté).
final currentUserProvider = Provider<Utilisateur?>((ref) {
  final session = ref.watch(sessionProvider);
  return session.valueOrNull;
});

/// Indique si une session est actuellement chargée (utilisé par le
/// routeur pour décider d'attendre avant de rediriger).
final isSessionLoadingProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session.isLoading;
});

#!/bin/bash
# ============================================================================
# SCRIPT 08 — Providers Riverpod (injection de dépendances et session)
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. lib/core/providers/repository_providers.dart
#        → LE point d'injection central. Pour chaque interface de
#          repository (script 05), expose UN SEUL provider qui retourne
#          soit l'implémentation locale (Hive), soit l'implémentation
#          API (Dio), selon AppConfig.dataMode. Tout le reste de
#          l'application dépend de CES providers, jamais directement
#          d'une classe "Local..." ou "Api...".
#   2. lib/features/auth/providers/session_provider.dart
#        → Gère l'état de connexion de l'utilisateur courant (qui
#          est connecté, sous quel rôle), avec restauration
#          automatique de la session au redémarrage de l'app.
#   3. lib/core/providers/connectivity_provider.dart
#        → Expose l'état de connexion réseau en continu, pour afficher
#          un indicateur "Hors-ligne" cohérent dans toute l'application.
#
# CHOIX TECHNIQUE — API RIVERPOD UTILISÉE :
#   On utilise Notifier/NotifierProvider et AsyncNotifier/
#   AsyncNotifierProvider (disponibles depuis Riverpod 2.0, SANS
#   nécessiter de génération de code). On évite volontairement
#   StateNotifierProvider/StateProvider : ces API sont marquées comme
#   dépréciées dans les versions très récentes de Riverpod (3.x) et
#   déplacées dans un import séparé — les utiliser aujourd'hui
#   créerait un risque de void/warning sur les futures mises à jour
#   du package. Notifier/AsyncNotifier sont l'API stable recommandée
#   actuellement, qu'on utilise ou non le code generator.
#
# RAPPEL DU MÉCANISME DE BASCULE LOCAL → API :
#   Dans repository_providers.dart, chaque provider contient un simple
#   "if (AppConfig.isLocal) return Local...(); else return Api...();"
#   Au script 09 (couche API dormante), on créera les classes "Api...".
#   Tant qu'elles n'existent pas encore, la branche "else" pointera
#   vers un message d'erreur explicite plutôt qu'un crash silencieux.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 08_riverpod_providers.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 08 terminé avec succès."
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 08/14 : Providers Riverpod"
echo "============================================================"

if [ ! -d "lib/data/repositories/local" ]; then
  echo "ERREUR : lib/data/repositories/local introuvable. Avez-vous exécuté le script 05 ?"
  exit 1
fi

mkdir -p lib/core/providers

# ============================================================================
# 1. PROVIDERS DE REPOSITORY — point d'injection central
# ============================================================================
cat > lib/core/providers/repository_providers.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_dispute_repository.dart';
import '../../domain/repositories/i_favorite_repository.dart';
import '../../domain/repositories/i_message_repository.dart';
import '../../domain/repositories/i_mission_repository.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../domain/repositories/i_seller_request_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../data/repositories/local/local_auth_repository.dart';
import '../../data/repositories/local/local_category_repository.dart';
import '../../data/repositories/local/local_dispute_repository.dart';
import '../../data/repositories/local/local_favorite_repository.dart';
import '../../data/repositories/local/local_message_repository.dart';
import '../../data/repositories/local/local_mission_repository.dart';
import '../../data/repositories/local/local_notification_repository.dart';
import '../../data/repositories/local/local_order_repository.dart';
import '../../data/repositories/local/local_payment_repository.dart';
import '../../data/repositories/local/local_product_repository.dart';
import '../../data/repositories/local/local_seller_request_repository.dart';
import '../../data/repositories/local/local_user_repository.dart';

/// ════════════════════════════════════════════════════════════════
/// POINT D'INJECTION CENTRAL DE L'APPLICATION
/// ════════════════════════════════════════════════════════════════
///
/// Chaque provider ci-dessous retourne une IMPLÉMENTATION CONCRÈTE
/// d'une interface du domaine, choisie selon AppConfig.dataMode.
///
/// RÈGLE D'OR : tout le reste de l'application (providers de feature,
/// écrans) ne doit JAMAIS importer directement une classe
/// "Local...Repository" ou "Api...Repository". Il doit toujours
/// passer par ces providers, en utilisant le TYPE D'INTERFACE
/// (ex: ref.watch(productRepositoryProvider) retourne un
/// IProductRepository, jamais explicitement un LocalProductRepository).
///
/// C'est cette unique règle qui permet de basculer l'intégralité de
/// l'application vers l'API en ne modifiant QUE ce fichier.

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalAuthRepository();
  }
  throw UnimplementedError(
    'ApiAuthRepository sera branché au script 09. '
    'Passez AppConfig.dataMode à DataMode.local en attendant.',
  );
});

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalProductRepository();
  }
  throw UnimplementedError('ApiProductRepository sera branché au script 09.');
});

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalOrderRepository();
  }
  throw UnimplementedError('ApiOrderRepository sera branché au script 09.');
});

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalPaymentRepository();
  }
  throw UnimplementedError('ApiPaymentRepository sera branché au script 09.');
});

final sellerRequestRepositoryProvider = Provider<ISellerRequestRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalSellerRequestRepository();
  }
  throw UnimplementedError('ApiSellerRequestRepository sera branché au script 09.');
});

final missionRepositoryProvider = Provider<IMissionRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalMissionRepository();
  }
  throw UnimplementedError('ApiMissionRepository sera branché au script 09.');
});

final disputeRepositoryProvider = Provider<IDisputeRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalDisputeRepository();
  }
  throw UnimplementedError('ApiDisputeRepository sera branché au script 09.');
});

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalNotificationRepository();
  }
  throw UnimplementedError('ApiNotificationRepository sera branché au script 09.');
});

final messageRepositoryProvider = Provider<IMessageRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalMessageRepository();
  }
  throw UnimplementedError('ApiMessageRepository sera branché au script 09.');
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalCategoryRepository();
  }
  throw UnimplementedError('ApiCategoryRepository sera branché au script 09.');
});

final favoriteRepositoryProvider = Provider<IFavoriteRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalFavoriteRepository();
  }
  throw UnimplementedError('ApiFavoriteRepository sera branché au script 09.');
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  if (AppConfig.isLocal) {
    return LocalUserRepository();
  }
  throw UnimplementedError('ApiUserRepository sera branché au script 09.');
});
EOF
echo "→ lib/core/providers/repository_providers.dart créé."

# ============================================================================
# 2. PROVIDER DE CONNECTIVITÉ RÉSEAU
# ============================================================================
cat > lib/core/providers/connectivity_provider.dart << 'EOF'
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Expose l'état de connexion réseau en continu (Stream), pour
/// afficher un indicateur "Hors-ligne" cohérent dans toute
/// l'application. Particulièrement utile pour préparer la transition
/// vers le mode API : en mode local, le réseau n'est jamais
/// indispensable, mais on veut déjà avoir l'infrastructure prête.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Raccourci pratique : true si l'appareil a une connexion active
/// (Wi-Fi ou données mobiles), false sinon. Pendant le chargement
/// initial de l'état, considéré comme connecté par défaut pour ne
/// pas afficher un bandeau "Hors-ligne" qui clignote au démarrage.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => true,
    error: (_, __) => true,
  );
});
EOF
echo "→ lib/core/providers/connectivity_provider.dart créé."

# ============================================================================
# 3. PROVIDER DE SESSION UTILISATEUR
# ============================================================================
mkdir -p lib/features/auth/providers

cat > lib/features/auth/providers/session_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/utilisateur.dart';

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
  }

  /// Connecte directement un compte de démonstration, sans mot de
  /// passe, conformément au choix validé pour le mode local.
  Future<void> loginAsDemo(Utilisateur compteDemo) async {
    state = const AsyncLoading();
    final authRepo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(
      () => authRepo.loginAsDemoAccount(compteDemo.id),
    );
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
EOF
echo "→ lib/features/auth/providers/session_provider.dart créé."

# ============================================================================
# 4. PROVIDER DES COMPTES DE DÉMONSTRATION (pour l'écran de sélection)
# ============================================================================
cat > lib/features/auth/providers/demo_accounts_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/utilisateur.dart';

/// Charge la liste des comptes de démonstration disponibles, affichée
/// sur l'écran de sélection de compte (voir choix validé : connexion
/// par sélection plutôt que par OTP simulé).
final demoAccountsProvider = FutureProvider<List<Utilisateur>>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final comptes = await authRepo.getDemoAccounts();
  // N'affiche pas le compte "Support" technique dans la liste de
  // sélection : ce compte existe uniquement pour peupler la
  // conversation de support, pas pour être incarné par l'utilisateur
  // testant l'application.
  return comptes.where((u) => u.telephone != '670000000').toList();
});
EOF
echo "→ lib/features/auth/providers/demo_accounts_provider.dart créé."

echo ""
echo "============================================================"
echo "  ✔ Script 08 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • repository_providers.dart : 12 providers d'injection,"
echo "    chacun basculant automatiquement Local <-> API selon"
echo "    AppConfig.dataMode."
echo "  • connectivity_provider.dart : état réseau en continu."
echo "  • session_provider.dart : connexion, déconnexion, restauration"
echo "    automatique de session au démarrage."
echo "  • demo_accounts_provider.dart : liste des comptes de"
echo "    démonstration pour l'écran de sélection."
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 09 : main.dart"
echo "  et le squelette du routeur complet avec ses redirections"
echo "  selon le rôle et l'état de session — la dernière pièce avant"
echo "  de commencer à construire les écrans eux-mêmes."
echo ""

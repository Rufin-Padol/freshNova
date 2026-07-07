import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/categorie.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/demande_vendeur.dart';
import '../../../domain/entities/litige.dart';
import '../../../domain/entities/mission.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/entities/proprietaire.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/enums/dispute_status.dart';
import '../../../domain/enums/mission_status.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/enums/seller_request_status.dart';
import '../../../domain/enums/user_role.dart';
import '../../auth/providers/session_provider.dart';

const _uuid = Uuid();

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

/// Nombre de missions confiées à un agent (tous statuts confondus),
/// utilisé pour donner à l'admin un aperçu de charge de travail.
final missionCountByAgentProvider = FutureProvider.family<int, String>((ref, agentId) async {
  final repo = ref.watch(missionRepositoryProvider);
  final missions = await repo.getByAgent(agentId);
  return missions.length;
});

/// Toutes les commandes, triées de la plus récente à la plus ancienne.
final allOrdersAdminProvider = FutureProvider<List<Commande>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  final all = await repo.getAll();
  all.sort((a, b) => b.dateCommande.compareTo(a.dateCommande));
  return all;
});

/// Tous les litiges, triés du plus récent au plus ancien.
final allDisputesAdminProvider = FutureProvider<List<Litige>>((ref) async {
  final repo = ref.watch(disputeRepositoryProvider);
  final all = await repo.getAll();
  all.sort((a, b) => b.dateOuverture.compareTo(a.dateOuverture));
  return all;
});

/// Toutes les demandes vendeurs, triées par date décroissante — étape
/// centrale du cycle métier (traitement admin) : c'est ici que l'admin
/// examine chaque soumission et assigne un agent pour la collecte.
final allSellerRequestsAdminProvider = FutureProvider<List<DemandeVendeur>>((ref) async {
  final repo = ref.watch(sellerRequestRepositoryProvider);
  final all = await repo.getAll();
  all.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
  return all;
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

/// Traite le maillon central du cycle métier : transforme une
/// [DemandeVendeur] en [Mission] de collecte assignée à un agent, et
/// crée le [Produit] brouillon correspondant que l'agent fera
/// progresser sur le terrain (voir agent_provider.dart, déjà
/// fonctionnel une fois qu'une mission existe).
class AdminSellerRequestNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> assignerAgent(DemandeVendeur demande, String agentId) async {
    final missionId = _uuid.v4();
    final produitId = _uuid.v4();

    // Le propriétaire est d'abord dérivé du compte vendeur qui a soumis
    // la demande (nom, téléphone) — l'agent n'aura qu'à confirmer ou
    // corriger sur place si la personne présente est différente,
    // plutôt que de repartir d'un formulaire vide à chaque collecte.
    final proprietaireId = await _resoudreProprietaireDepuisVendeur(demande.vendeurId);

    // Le taux de commission dépend désormais de la catégorie
    // (configurable par le Super Admin), plutôt que d'une constante
    // unique pour tout le catalogue.
    final categories = await ref.read(categoryRepositoryProvider).getAll();
    final tauxCommission = categories
        .firstWhere(
          (c) => c.id == demande.categorieId,
          orElse: () => categories.isNotEmpty
              ? categories.first
              : const Categorie(id: '', nom: '', tauxCommission: AppConstants.defaultCommissionRate),
        )
        .tauxCommission;

    final mission = Mission(
      id: missionId,
      type: MissionType.collecte,
      statut: MissionStatus.assignee,
      // Visite proposée sous 24h par défaut — l'agent ajuste l'heure
      // exacte avec le vendeur une fois la mission reçue.
      dateHeure: DateTime.now().add(const Duration(hours: 24)),
      agentId: agentId,
      referenceId: demande.id,
      latitude: demande.latitude,
      longitude: demande.longitude,
    );
    await ref.read(missionRepositoryProvider).save(mission);

    final produit = Produit(
      id: produitId,
      titre: demande.typeProduitSouhaite,
      description: demande.descriptionInitiale,
      prix: demande.prixSouhaite,
      etat: ProductCondition.bonEtat,
      statut: ProductStatus.missionAssignee,
      categorieId: demande.categorieId,
      dateCreation: DateTime.now(),
      vendeurId: demande.vendeurId,
      agentId: agentId,
      localisation: demande.zone,
      tauxCommission: tauxCommission,
      missionId: missionId,
      proprietaireId: proprietaireId,
    );
    await ref.read(productRepositoryProvider).save(produit);

    await ref.read(sellerRequestRepositoryProvider).save(
          demande.copyWith(
            statut: SellerRequestStatus.agentAssigne,
            missionId: missionId,
          ),
        );

    ref.invalidate(allSellerRequestsAdminProvider);
    ref.invalidate(allProductsAdminProvider);
  }

  /// Retrouve le [Proprietaire] déjà lié au même numéro de téléphone
  /// que le compte vendeur (évite les doublons si la même personne
  /// vend plusieurs fois), ou en crée un nouveau à partir de son nom
  /// et téléphone de compte.
  Future<String?> _resoudreProprietaireDepuisVendeur(String vendeurId) async {
    final vendeur = await ref.read(userRepositoryProvider).getById(vendeurId);
    if (vendeur == null) return null;

    final proprietaireRepo = ref.read(proprietaireRepositoryProvider);
    final existants = await proprietaireRepo.getAll();
    for (final p in existants) {
      if (p.telephone == vendeur.telephone) return p.id;
    }

    final nouveau = Proprietaire(
      id: _uuid.v4(),
      nom: vendeur.nomComplet,
      telephone: vendeur.telephone,
      ville: vendeur.ville,
      dateCreation: DateTime.now(),
    );
    await proprietaireRepo.save(nouveau);
    return nouveau.id;
  }
}

final adminSellerRequestNotifierProvider =
    NotifierProvider<AdminSellerRequestNotifier, void>(AdminSellerRequestNotifier.new);

/// Actions admin sur les litiges (décision, remboursement, clôture).
class AdminDisputeNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> resoudre(
    Litige litige, {
    required DisputeStatus statut,
    required String decision,
    double? montantRembourse,
  }) async {
    final admin = ref.read(currentUserProvider);
    final repo = ref.read(disputeRepositoryProvider);
    await repo.save(litige.copyWith(
      statut: statut,
      decision: decision,
      montantRembourse: montantRembourse,
      traiteParAdminId: admin?.id,
    ));
    ref.invalidate(allDisputesAdminProvider);
  }
}

final adminDisputeNotifierProvider =
    NotifierProvider<AdminDisputeNotifier, void>(AdminDisputeNotifier.new);

/// Actions admin sur les commandes (suivi/changement de statut).
class AdminOrderNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> changerStatut(String commandeId, OrderStatus statut) async {
    final repo = ref.read(orderRepositoryProvider);
    await repo.updateStatut(commandeId, statut);
    ref.invalidate(allOrdersAdminProvider);
  }
}

final adminOrderNotifierProvider =
    NotifierProvider<AdminOrderNotifier, void>(AdminOrderNotifier.new);

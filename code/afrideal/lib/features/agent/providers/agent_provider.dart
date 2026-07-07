import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/mission.dart';
import '../../../domain/entities/photo.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/enums/mission_status.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/enums/proof_type.dart';
import '../../../domain/enums/seller_request_status.dart';
import '../../auth/providers/session_provider.dart';

const _uuid = Uuid();

/// Missions de l'agent connecté, triées par date d'intervention.
final myMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return [];
  final repo = ref.watch(missionRepositoryProvider);
  final missions = await repo.getByAgent(utilisateur.id);
  missions.sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
  return missions;
});

/// Détail d'une mission unique.
final missionDetailProvider = FutureProvider.family<Mission?, String>((ref, id) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.getById(id);
});

/// Statistiques de performance de l'agent connecté, calculées à
/// partir de l'historique complet de ses missions — affichées sur son
/// tableau de bord (missions complétées ce mois, taux de réussite,
/// zones couvertes).
class AgentStats {
  final int missionsCompleteesCeMois;
  final double tauxReussite;
  final int zonesCouvertes;

  const AgentStats({
    required this.missionsCompleteesCeMois,
    required this.tauxReussite,
    required this.zonesCouvertes,
  });
}

final agentStatsProvider = Provider<AgentStats>((ref) {
  final missions = ref.watch(myMissionsProvider).valueOrNull ?? [];
  final maintenant = DateTime.now();

  final completeesCeMois = missions.where((m) {
    return m.statut == MissionStatus.complete &&
        m.dateHeure.year == maintenant.year &&
        m.dateHeure.month == maintenant.month;
  }).length;

  final completees = missions.where((m) => m.statut == MissionStatus.complete).length;
  final echecs = missions.where((m) => m.statut == MissionStatus.echec).length;
  final total = completees + echecs;
  final taux = total == 0 ? 0.0 : (completees / total) * 100;

  // Zones distinctes approximées par arrondi des coordonnées GPS
  // (≈1 km de résolution), faute de champ "zone" dédié sur la mission.
  final zones = <String>{};
  for (final m in missions) {
    if (m.latitude != null && m.longitude != null) {
      zones.add('${m.latitude!.toStringAsFixed(2)},${m.longitude!.toStringAsFixed(2)}');
    }
  }

  return AgentStats(
    missionsCompleteesCeMois: completeesCeMois,
    tauxReussite: taux,
    zonesCouvertes: zones.length,
  );
});

/// Produit brouillon (créé à l'assignation) lié à une mission de
/// collecte donnée — c'est ce produit que l'agent complète sur place.
final produitDeMissionProvider = FutureProvider.family<Produit?, String>((ref, missionId) async {
  final mission = await ref.watch(missionDetailProvider(missionId).future);
  if (mission == null) return null;
  final repo = ref.watch(productRepositoryProvider);
  final produits = await repo.getByAgent(mission.agentId);
  for (final p in produits) {
    if (p.missionId == missionId) return p;
  }
  return null;
});

/// Pilote les actions de terrain de l'agent sur une mission.
class AgentMissionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// L'agent initie lui-même une collecte, sans assignation préalable
  /// de l'admin (démarchage terrain proactif) — crée directement la
  /// mission (déjà "sur site", l'agent étant physiquement présent) et
  /// le produit brouillon associés. Reste soumis à la même relecture
  /// et publication par l'admin que le reste du catalogue.
  Future<String> creerCollecteAutoInitiee({
    required String agentId,
    required String proprietaireId,
    required String titre,
    required String categorieId,
    required double tauxCommission,
    required double prix,
    required String localisation,
    double? latitude,
    double? longitude,
  }) async {
    final missionId = _uuid.v4();
    final produitId = _uuid.v4();

    final mission = Mission(
      id: missionId,
      type: MissionType.collecte,
      statut: MissionStatus.surSite,
      dateHeure: DateTime.now(),
      agentId: agentId,
      referenceId: '',
      latitude: latitude,
      longitude: longitude,
    );
    await ref.read(missionRepositoryProvider).save(mission);

    final produit = Produit(
      id: produitId,
      titre: titre,
      description: '',
      prix: prix,
      etat: ProductCondition.bonEtat,
      statut: ProductStatus.missionAssignee,
      categorieId: categorieId,
      dateCreation: DateTime.now(),
      vendeurId: '',
      agentId: agentId,
      localisation: localisation,
      tauxCommission: tauxCommission,
      missionId: missionId,
      proprietaireId: proprietaireId,
    );
    await ref.read(productRepositoryProvider).save(produit);

    ref.invalidate(myMissionsProvider);
    return missionId;
  }

  Future<void> demarrer(Mission mission) async {
    state = const AsyncLoading();
    try {
      await _saveMission(mission.copyWith(statut: MissionStatus.enRoute));
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> signalerArrivee(Mission mission) async {
    state = const AsyncLoading();
    try {
      await _saveMission(mission.copyWith(statut: MissionStatus.surSite));
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Valide une collecte réussie : l'agent vient de produire la fiche
  /// produit complète sur place (propriétaire identifié, preuve de
  /// propriété, photos officielles, dimensions, état réel, défauts,
  /// prix confirmé). Le produit passe en `enTraitement` — il sera
  /// relu et publié par l'admin (voir AdminProductEditScreen).
  Future<void> validerCollecteComplete(
    Mission mission, {
    required String proprietaireId,
    required ProofType preuveType,
    required String preuveValeur,
    required List<Photo> photosOfficielles,
    required String titre,
    required String categorieId,
    required String? dimensions,
    required ProductCondition etat,
    required String? defautsConnus,
    required double prixConfirme,
  }) async {
    state = const AsyncLoading();
    try {
      await _saveMission(mission.copyWith(
        statut: MissionStatus.complete,
        proprietaireId: proprietaireId,
        preuveProprieteType: preuveType,
        preuveProprieteValeur: preuveValeur,
        photosCount: photosOfficielles.length,
      ));

      final requestRepo = ref.read(sellerRequestRepositoryProvider);
      final demande = await requestRepo.getById(mission.referenceId);
      if (demande != null) {
        await requestRepo.save(
          demande.copyWith(statut: SellerRequestStatus.terminee),
        );
      }

      final productRepo = ref.read(productRepositoryProvider);
      final produits = await productRepo.getByAgent(mission.agentId);
      Produit? produit;
      for (final p in produits) {
        if (p.missionId == mission.id) {
          produit = p;
          break;
        }
      }

      if (produit != null) {
        await productRepo.save(produit.copyWith(
          titre: titre,
          categorieId: categorieId,
          dimensions: dimensions,
          etat: etat,
          defautsConnus: defautsConnus,
          prix: prixConfirme,
          proprietaireId: proprietaireId,
          photos: photosOfficielles,
          statut: ProductStatus.enTraitement,
        ));
      }

      ref.invalidate(produitDeMissionProvider(mission.id));
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Signale un refus : le vendeur n'a pas pu prouver sa propriété.
  Future<void> signalerRefus(Mission mission, String raison) async {
    state = const AsyncLoading();
    try {
      await _saveMission(
        mission.copyWith(statut: MissionStatus.echec, raisonRefus: raison),
      );

      final requestRepo = ref.read(sellerRequestRepositoryProvider);
      final demande = await requestRepo.getById(mission.referenceId);
      if (demande != null) {
        await requestRepo.save(
          demande.copyWith(
            statut: SellerRequestStatus.refusee,
            raisonRefus: raison,
          ),
        );
      }
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> _saveMission(Mission mission) async {
    final repo = ref.read(missionRepositoryProvider);
    await repo.save(mission);
    ref.invalidate(myMissionsProvider);
    ref.invalidate(missionDetailProvider(mission.id));
  }
}

final agentMissionNotifierProvider =
    NotifierProvider<AgentMissionNotifier, AsyncValue<void>>(
  AgentMissionNotifier.new,
);

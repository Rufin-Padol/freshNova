import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/mission.dart';
import '../../../domain/enums/mission_status.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/enums/seller_request_status.dart';
import '../../auth/providers/session_provider.dart';

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

/// Pilote les actions de terrain de l'agent sur une mission.
class AgentMissionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

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

  /// Valide une collecte réussie : met à jour le statut de la mission
  /// ET celui du produit/demande vendeur associé.
  Future<void> validerCollecte(Mission mission) async {
    state = const AsyncLoading();
    try {
      await _saveMission(mission.copyWith(statut: MissionStatus.complete));

      final requestRepo = ref.read(sellerRequestRepositoryProvider);
      final demande = await requestRepo.getById(mission.referenceId);
      if (demande != null) {
        await requestRepo.save(
          demande.copyWith(statut: SellerRequestStatus.terminee),
        );
      }

      final productRepo = ref.read(productRepositoryProvider);
      final produits = await productRepo.getByAgent(mission.agentId);
      for (final p in produits) {
        if (p.statut == ProductStatus.enVerification) {
          await productRepo.updateStatut(p.id, ProductStatus.enTraitement);
        }
      }

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

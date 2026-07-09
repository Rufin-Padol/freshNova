import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/proprietaire.dart';

const _uuid = Uuid();

/// Tous les propriétaires connus de la plateforme — registre partagé
/// entre agents, indépendant des comptes vendeurs de l'app (un
/// propriétaire n'a pas besoin d'installer TrustNova pour vendre).
final allProprietairesProvider = FutureProvider<List<Proprietaire>>((ref) async {
  final repo = ref.watch(proprietaireRepositoryProvider);
  final all = await repo.getAll();
  all.sort((a, b) => a.nom.compareTo(b.nom));
  return all;
});

/// Propriétaire déjà pré-résolu à l'assignation (depuis le compte
/// vendeur) — utilisé pour pré-remplir le formulaire de collecte sans
/// que l'agent ait à le rechercher à nouveau.
final proprietaireByIdProvider =
    FutureProvider.family<Proprietaire?, String>((ref, id) async {
  final repo = ref.watch(proprietaireRepositoryProvider);
  return repo.getById(id);
});

class ProprietaireNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<Proprietaire> creer({
    required String nom,
    required String telephone,
    String? ville,
  }) async {
    final proprietaire = Proprietaire(
      id: _uuid.v4(),
      nom: nom,
      telephone: telephone,
      ville: ville,
      dateCreation: DateTime.now(),
    );
    await ref.read(proprietaireRepositoryProvider).save(proprietaire);
    ref.invalidate(allProprietairesProvider);
    return proprietaire;
  }
}

final proprietaireNotifierProvider =
    NotifierProvider<ProprietaireNotifier, void>(ProprietaireNotifier.new);

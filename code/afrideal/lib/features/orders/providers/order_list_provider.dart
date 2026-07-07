import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/commande.dart';
import '../../auth/providers/session_provider.dart';

/// Commandes de l'acheteur connecté, triées des plus récentes aux
/// plus anciennes.
final myOrdersProvider = FutureProvider<List<Commande>>((ref) async {
  final utilisateur = ref.watch(currentUserProvider);
  if (utilisateur == null) return [];
  final repo = ref.watch(orderRepositoryProvider);
  final commandes = await repo.getByAcheteur(utilisateur.id);
  commandes.sort((a, b) => b.dateCommande.compareTo(a.dateCommande));
  return commandes;
});

/// Détail d'une commande unique, utilisé par l'écran de suivi.
final orderDetailProvider = FutureProvider.family<Commande?, String>((ref, orderId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getById(orderId);
});

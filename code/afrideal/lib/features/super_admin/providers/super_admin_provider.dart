import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/categorie.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/user_role.dart';
import '../../admin/providers/admin_provider.dart';

const _uuid = Uuid();

/// Comptes Admin de la plateforme — gérés exclusivement par le Super
/// Admin (contrôle total, y compris sur la partie Admin elle-même).
final adminAccountsProvider = FutureProvider<List<Utilisateur>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getByRole(UserRole.admin);
});

/// Toutes les catégories avec leur taux de commission actuel.
final allCategoriesAdminProvider = FutureProvider<List<Categorie>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final all = await repo.getAll();
  all.sort((a, b) => a.ordreAffichage.compareTo(b.ordreAffichage));
  return all;
});

/// KPIs stratégiques globaux, vus uniquement par le Super Admin.
class SuperAdminStats {
  final double revenusCommissions;
  final int totalUtilisateurs;
  final int totalProduitsEnVente;
  final int totalCommandesLivrees;

  const SuperAdminStats({
    required this.revenusCommissions,
    required this.totalUtilisateurs,
    required this.totalProduitsEnVente,
    required this.totalCommandesLivrees,
  });
}

final superAdminStatsProvider = FutureProvider<SuperAdminStats>((ref) async {
  final produits = await ref.watch(allProductsAdminProvider.future);
  final utilisateurs = await ref.watch(allUsersAdminProvider.future);
  final commandes = await ref.watch(allOrdersAdminProvider.future);

  final commandesLivrees = commandes.where((c) => c.statut == OrderStatus.livree).toList();

  // Commission perçue = différence entre le prix affiché du produit
  // vendu et son montant net vendeur (voir Produit.montantNetVendeur).
  double revenus = 0;
  for (final c in commandesLivrees) {
    for (final entry in c.lignes.entries) {
      final produit = produits.where((p) => p.id == entry.key).firstOrNull;
      if (produit != null) {
        revenus += (produit.prix - produit.montantNetVendeur) * entry.value;
      }
    }
  }

  return SuperAdminStats(
    revenusCommissions: revenus,
    totalUtilisateurs: utilisateurs.length,
    totalProduitsEnVente: produits.where((p) => p.statut.isPurchasable).length,
    totalCommandesLivrees: commandesLivrees.length,
  );
});

class SuperAdminNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Crée un nouveau compte Admin, sans jamais toucher à la session en
  /// cours (voir IAuthRepository.creerCompteSansConnexion).
  Future<void> creerAdmin({
    required String nom,
    required String prenom,
    required String telephone,
    required String motDePasse,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.creerCompteSansConnexion(
      Utilisateur(
        id: _uuid.v4(),
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        motDePasseHash: '',
        role: UserRole.admin,
        dateInscription: DateTime.now(),
      ),
      motDePasse,
    );
    ref.invalidate(adminAccountsProvider);
    ref.invalidate(allUsersAdminProvider);
  }

  Future<void> modifierCommission(Categorie categorie, double nouveauTaux) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.save(categorie.copyWith(tauxCommission: nouveauTaux));
    ref.invalidate(allCategoriesAdminProvider);
  }
}

final superAdminNotifierProvider =
    NotifierProvider<SuperAdminNotifier, void>(SuperAdminNotifier.new);

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

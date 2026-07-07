import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/categorie.dart';

/// Charge la liste des catégories de produits, utilisée par la
/// boutique pour les filtres et par le formulaire de soumission
/// vendeur pour le choix de catégorie.
final categoriesProvider = FutureProvider<List<Categorie>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
});

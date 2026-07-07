import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/repositories/i_favorite_repository.dart';

/// Implémentation locale des favoris.
///
/// Stockage volontairement simple : une seule entrée par utilisateur,
/// dont la clé est l'id utilisateur et la valeur une liste JSON
/// d'identifiants de produits favoris.
class LocalFavoriteRepository implements IFavoriteRepository {
  Box<String> get _box => Hive.box<String>(StorageKeys.favoritesBox);

  @override
  Future<List<String>> getFavoriteProductIds(String userId) async {
    final raw = _box.get(userId);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addFavorite(String userId, String produitId) async {
    final current = await getFavoriteProductIds(userId);
    if (!current.contains(produitId)) {
      current.add(produitId);
      await _box.put(userId, jsonEncode(current));
    }
  }

  @override
  Future<void> removeFavorite(String userId, String produitId) async {
    final current = await getFavoriteProductIds(userId);
    current.remove(produitId);
    await _box.put(userId, jsonEncode(current));
  }

  @override
  Future<bool> isFavorite(String userId, String produitId) async {
    final current = await getFavoriteProductIds(userId);
    return current.contains(produitId);
  }
}

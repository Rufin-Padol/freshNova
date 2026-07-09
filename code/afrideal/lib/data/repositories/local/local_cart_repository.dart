import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/repositories/i_cart_repository.dart';

/// Implémentation locale du panier.
///
/// Stockage volontairement simple : une seule entrée par utilisateur,
/// dont la clé est l'id utilisateur et la valeur une liste JSON
/// d'identifiants de produits ajoutés au panier (même schéma que
/// LocalFavoriteRepository).
class LocalCartRepository implements ICartRepository {
  Box<String> get _box => Hive.box<String>(StorageKeys.cartBox);

  @override
  Future<List<String>> getCartProductIds(String userId) async {
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
  Future<void> addToCart(String userId, String produitId) async {
    final current = await getCartProductIds(userId);
    if (!current.contains(produitId)) {
      current.add(produitId);
      await _box.put(userId, jsonEncode(current));
    }
  }

  @override
  Future<void> removeFromCart(String userId, String produitId) async {
    final current = await getCartProductIds(userId);
    current.remove(produitId);
    await _box.put(userId, jsonEncode(current));
  }

  @override
  Future<bool> isInCart(String userId, String produitId) async {
    final current = await getCartProductIds(userId);
    return current.contains(produitId);
  }
}

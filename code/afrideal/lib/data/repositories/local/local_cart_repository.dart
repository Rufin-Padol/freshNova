import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/repositories/i_cart_repository.dart';

/// Implémentation locale du panier.
///
/// Stockage volontairement simple : une seule entrée par utilisateur,
/// dont la clé est l'id utilisateur et la valeur un objet JSON
/// {produitId: quantite}.
class LocalCartRepository implements ICartRepository {
  Box<String> get _box => Hive.box<String>(StorageKeys.cartBox);

  @override
  Future<Map<String, int>> getCartItems(String userId) async {
    final raw = _box.get(userId);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((id, quantite) => MapEntry(id as String, (quantite as num).toInt()));
      }
      // Repli sur l'ancien format (liste d'ids, quantité implicite 1)
      // pour les paniers créés avant l'ajout de la quantité.
      if (decoded is List) {
        return {for (final id in decoded.cast<String>()) id: 1};
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> setQuantite(String userId, String produitId, int quantite) async {
    final current = await getCartItems(userId);
    if (quantite <= 0) {
      current.remove(produitId);
    } else {
      current[produitId] = quantite;
    }
    await _box.put(userId, jsonEncode(current));
  }
}

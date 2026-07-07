import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../core/errors/app_exception.dart';

/// Outil générique de stockage d'objets sérialisables en JSON dans une
/// Box Hive<String>.
///
/// Chaque entité est stockée sous la forme : clé = id de l'objet,
/// valeur = chaîne JSON de l'objet. Ce store ne connaît AUCUN type
/// métier précis : il manipule des `Map<String, dynamic>` génériques
/// et délègue toute la conversion vers/depuis un type concret aux
/// fonctions `toJson`/`fromJson` qu'on lui passe en paramètre.
///
/// C'est cette généricité qui permet d'écrire un seul LocalJsonStore
/// et de le réutiliser pour les 12 entités de l'application, plutôt
/// que de dupliquer la même logique de lecture/écriture 12 fois.
class LocalJsonStore<T> {
  final String boxName;
  final Map<String, dynamic> Function(T item) toJson;
  final T Function(Map<String, dynamic> json) fromJson;
  final String Function(T item) idOf;

  LocalJsonStore({
    required this.boxName,
    required this.toJson,
    required this.fromJson,
    required this.idOf,
  });

  Box<String> get _box => Hive.box<String>(boxName);

  /// Retourne tous les éléments stockés dans cette box.
  /// Les entrées corrompues (JSON invalide) sont ignorées silencieusement
  /// plutôt que de faire planter tout l'écran qui affiche la liste.
  Future<List<T>> getAll() async {
    final items = <T>[];
    for (final rawJson in _box.values) {
      try {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        items.add(fromJson(map));
      } catch (_) {
        // Entrée corrompue : on l'ignore pour ne pas bloquer le reste.
        continue;
      }
    }
    return items;
  }

  /// Retourne un élément par son identifiant, ou null s'il n'existe pas.
  Future<T?> getById(String id) async {
    final rawJson = _box.get(id);
    if (rawJson == null) return null;
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Insère ou met à jour un élément (identifié par [idOf]).
  Future<void> save(T item) async {
    try {
      final id = idOf(item);
      final json = jsonEncode(toJson(item));
      await _box.put(id, json);
    } catch (e) {
      throw StorageException('Impossible d\'enregistrer les données : $e');
    }
  }

  /// Insère ou met à jour plusieurs éléments en une seule opération,
  /// plus efficace que d'appeler [save] en boucle.
  Future<void> saveAll(List<T> items) async {
    try {
      final entries = <String, String>{
        for (final item in items) idOf(item): jsonEncode(toJson(item)),
      };
      await _box.putAll(entries);
    } catch (e) {
      throw StorageException('Impossible d\'enregistrer les données : $e');
    }
  }

  /// Supprime un élément par son identifiant.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Supprime tous les éléments de cette box.
  Future<void> clear() async {
    await _box.clear();
  }

  /// Indique si la box est vide (utile pour décider d'insérer les
  /// données de démonstration au tout premier lancement de l'app).
  bool get isEmpty => _box.isEmpty;
}

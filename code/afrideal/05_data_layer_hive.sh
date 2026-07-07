#!/bin/bash
# ============================================================================
# SCRIPT 05 — Service Hive et Repositories locaux
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. lib/data/local/datasources/hive_service.dart
#        → Initialise Hive (compatible Android/iOS/Web) et ouvre TOUTES
#          les box nécessaires au démarrage de l'application, en une
#          seule fois, de façon centralisée.
#   2. lib/data/local/datasources/local_json_store.dart
#        → Petit outil générique de lecture/écriture JSON dans une Box
#          Hive<String>. C'est la brique de base réutilisée par TOUS les
#          repositories locaux : elle sait stocker/lire/supprimer une
#          liste d'objets sérialisés en JSON, sans jamais dépendre du
#          type concret de l'objet stocké.
#   3. lib/domain/repositories/
#        → les INTERFACES abstraites (contrats) que chaque repository
#          (local aujourd'hui, API demain) doit respecter. Ce sont CES
#          interfaces que les providers (script suivant) utilisent —
#          jamais une implémentation concrète directement.
#   4. lib/data/repositories/local/
#        → l'implémentation LOCALE (Hive) de chaque interface.
#
# RAPPEL DU PRINCIPE D'INVERSION DE DÉPENDANCE (déjà posé au script 02) :
#   Écran → utilise → IProduitRepository (interface, lib/domain)
#                            ▲
#                            │ implémente
#                            │
#              LocalProduitRepository (lib/data/repositories/local)
#              ApiProduitRepository   (créé au script 06, dormant)
#
#   Le jour où AppConfig.dataMode passe à DataMode.api, c'est le
#   "Provider" Riverpod (script 07+) qui injectera ApiProduitRepository
#   à la place de LocalProduitRepository — l'écran ne voit AUCUNE
#   différence car il ne connaît que l'interface IProduitRepository.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 05_data_layer_hive.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 05 terminé avec succès."
#   Aucune nouvelle dépendance, donc pas de pub get nécessaire.
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 05/14 : Service Hive et Repositories"
echo "============================================================"

if [ ! -d "lib/data/models" ]; then
  echo "ERREUR : lib/data/models introuvable. Avez-vous exécuté le script 04 ?"
  exit 1
fi

mkdir -p lib/data/local/datasources
mkdir -p lib/data/repositories/local
mkdir -p lib/domain/repositories

# ============================================================================
# 1. SERVICE HIVE — initialisation et ouverture de toutes les box
# ============================================================================
cat > lib/data/local/datasources/hive_service.dart << 'EOF'
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

/// Service centralisant l'initialisation de la base de données locale
/// Hive et l'ouverture de toutes les "box" (équivalent de tables) au
/// démarrage de l'application.
///
/// Toutes les box sont de type `Box<String>` : chaque enregistrement
/// est stocké comme une chaîne JSON (voir [LocalJsonStore]). Ce choix
/// élimine le besoin d'enregistrer un quelconque TypeAdapter Hive et
/// fonctionne de façon identique sur Android, iOS et Web.
class HiveService {
  HiveService._();

  static bool _initialized = false;

  /// Initialise Hive et ouvre toutes les box de l'application.
  /// Doit être appelé une seule fois, avant runApp(), depuis main.dart.
  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox<String>(StorageKeys.usersBox),
      Hive.openBox<String>(StorageKeys.productsBox),
      Hive.openBox<String>(StorageKeys.sellerRequestsBox),
      Hive.openBox<String>(StorageKeys.ordersBox),
      Hive.openBox<String>(StorageKeys.missionsBox),
      Hive.openBox<String>(StorageKeys.disputesBox),
      Hive.openBox<String>(StorageKeys.notificationsBox),
      Hive.openBox<String>(StorageKeys.messagesBox),
      Hive.openBox<String>(StorageKeys.favoritesBox),
      Hive.openBox<String>(StorageKeys.sessionBox),
      Hive.openBox<String>(StorageKeys.settingsBox),
      Hive.openBox<String>('categories_box'),
      Hive.openBox<String>('conversations_box'),
      Hive.openBox<String>('payments_box'),
    ]);

    _initialized = true;
  }

  /// Supprime TOUTES les données locales. Utile pour un bouton
  /// "Réinitialiser les données de démonstration" dans les réglages,
  /// ou pour les tests.
  static Future<void> clearAll() async {
    for (final boxName in [
      StorageKeys.usersBox,
      StorageKeys.productsBox,
      StorageKeys.sellerRequestsBox,
      StorageKeys.ordersBox,
      StorageKeys.missionsBox,
      StorageKeys.disputesBox,
      StorageKeys.notificationsBox,
      StorageKeys.messagesBox,
      StorageKeys.favoritesBox,
      StorageKeys.sessionBox,
      'categories_box',
      'conversations_box',
      'payments_box',
    ]) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<String>(boxName).clear();
      }
    }
  }
}
EOF
echo "→ lib/data/local/datasources/hive_service.dart créé."

# ============================================================================
# 2. LOCAL JSON STORE — brique générique de stockage JSON dans Hive
# ============================================================================
cat > lib/data/local/datasources/local_json_store.dart << 'EOF'
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
EOF
echo "→ lib/data/local/datasources/local_json_store.dart créé."

# ============================================================================
# 3. INTERFACES ABSTRAITES (lib/domain/repositories)
# ============================================================================
cat > lib/domain/repositories/i_auth_repository.dart << 'EOF'
import '../entities/utilisateur.dart';

/// Contrat d'authentification, indépendant du mode (local ou API).
///
/// En mode local, [login] vérifie les identifiants contre les comptes
/// de démonstration stockés dans Hive. En mode API, il enverra une
/// requête au serveur Spring Boot et stockera le token JWT renvoyé.
abstract class IAuthRepository {
  Future<Utilisateur?> login({
    required String telephone,
    required String motDePasse,
  });

  Future<Utilisateur> register(Utilisateur utilisateur, String motDePasse);

  Future<void> logout();

  /// Retourne l'utilisateur actuellement connecté, ou null si personne
  /// n'est connecté (utile pour restaurer la session au lancement).
  Future<Utilisateur?> getCurrentUser();

  /// Retourne la liste des comptes de démonstration disponibles
  /// (Acheteur test, Vendeur test, Agent test, Admin test, Super
  /// Admin test), utilisée par l'écran de sélection de compte démo.
  /// Cette méthode n'a de sens qu'en mode local ; en mode API elle
  /// renverra simplement une liste vide.
  Future<List<Utilisateur>> getDemoAccounts();

  /// Connecte directement un compte de démonstration par son
  /// identifiant, sans vérification de mot de passe. N'a de sens
  /// qu'en mode local (voir choix validé : sélection de compte démo
  /// plutôt que saisie d'identifiants). En mode API, cette méthode
  /// lèvera une UnimplementedError si jamais appelée par erreur.
  Future<Utilisateur?> loginAsDemoAccount(String userId);
}
EOF
echo "→ lib/domain/repositories/i_auth_repository.dart créé."

cat > lib/domain/repositories/i_product_repository.dart << 'EOF'
import '../entities/produit.dart';
import '../enums/product_status.dart';

/// Contrat de gestion des produits, indépendant du mode (local ou API).
abstract class IProductRepository {
  Future<List<Produit>> getAll();
  Future<Produit?> getById(String id);

  /// Produits affichables dans la boutique (statut "En vente"),
  /// avec filtres optionnels par catégorie et recherche texte.
  Future<List<Produit>> getEnVente({String? categorieId, String? recherche});

  Future<List<Produit>> getByVendeur(String vendeurId);
  Future<List<Produit>> getByAgent(String agentId);
  Future<List<Produit>> getByStatut(ProductStatus statut);

  Future<void> save(Produit produit);
  Future<void> updateStatut(String produitId, ProductStatus nouveauStatut);
  Future<void> delete(String id);
}
EOF
echo "→ lib/domain/repositories/i_product_repository.dart créé."

cat > lib/domain/repositories/i_order_repository.dart << 'EOF'
import '../entities/commande.dart';
import '../enums/order_status.dart';

abstract class IOrderRepository {
  Future<List<Commande>> getAll();
  Future<Commande?> getById(String id);
  Future<List<Commande>> getByAcheteur(String acheteurId);
  Future<void> save(Commande commande);
  Future<void> updateStatut(String commandeId, OrderStatus nouveauStatut);
}
EOF
echo "→ lib/domain/repositories/i_order_repository.dart créé."

cat > lib/domain/repositories/i_payment_repository.dart << 'EOF'
import '../entities/paiement.dart';

abstract class IPaymentRepository {
  Future<List<Paiement>> getByCommande(String commandeId);
  Future<void> save(Paiement paiement);
}
EOF
echo "→ lib/domain/repositories/i_payment_repository.dart créé."

cat > lib/domain/repositories/i_seller_request_repository.dart << 'EOF'
import '../entities/demande_vendeur.dart';

abstract class ISellerRequestRepository {
  Future<List<DemandeVendeur>> getAll();
  Future<DemandeVendeur?> getById(String id);
  Future<List<DemandeVendeur>> getByVendeur(String vendeurId);
  Future<void> save(DemandeVendeur demande);
  Future<void> delete(String id);
}
EOF
echo "→ lib/domain/repositories/i_seller_request_repository.dart créé."

cat > lib/domain/repositories/i_mission_repository.dart << 'EOF'
import '../entities/mission.dart';

abstract class IMissionRepository {
  Future<List<Mission>> getAll();
  Future<Mission?> getById(String id);
  Future<List<Mission>> getByAgent(String agentId);
  Future<void> save(Mission mission);
}
EOF
echo "→ lib/domain/repositories/i_mission_repository.dart créé."

cat > lib/domain/repositories/i_dispute_repository.dart << 'EOF'
import '../entities/litige.dart';

abstract class IDisputeRepository {
  Future<List<Litige>> getAll();
  Future<Litige?> getById(String id);
  Future<void> save(Litige litige);
}
EOF
echo "→ lib/domain/repositories/i_dispute_repository.dart créé."

cat > lib/domain/repositories/i_notification_repository.dart << 'EOF'
import '../entities/notification_entity.dart';

abstract class INotificationRepository {
  Future<List<NotificationEntity>> getByDestinataire(String userId);
  Future<void> save(NotificationEntity notification);
  Future<void> marquerCommeLue(String notificationId);
  Future<int> compterNonLues(String userId);
}
EOF
echo "→ lib/domain/repositories/i_notification_repository.dart créé."

cat > lib/domain/repositories/i_message_repository.dart << 'EOF'
import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class IMessageRepository {
  Future<List<Conversation>> getConversations(String userId);
  Future<List<Message>> getMessages(String conversationId);
  Future<void> envoyerMessage(Message message);
  Future<void> saveConversation(Conversation conversation);
}
EOF
echo "→ lib/domain/repositories/i_message_repository.dart créé."

cat > lib/domain/repositories/i_category_repository.dart << 'EOF'
import '../entities/categorie.dart';

abstract class ICategoryRepository {
  Future<List<Categorie>> getAll();
  Future<void> save(Categorie categorie);
  Future<void> delete(String id);
}
EOF
echo "→ lib/domain/repositories/i_category_repository.dart créé."

cat > lib/domain/repositories/i_favorite_repository.dart << 'EOF'
/// Gestion des favoris. Volontairement simple (juste une liste
/// d'identifiants de produits par utilisateur), sans entité dédiée,
/// car aucune donnée supplémentaire n'est nécessaire au-delà du lien
/// utilisateur-produit.
abstract class IFavoriteRepository {
  Future<List<String>> getFavoriteProductIds(String userId);
  Future<void> addFavorite(String userId, String produitId);
  Future<void> removeFavorite(String userId, String produitId);
  Future<bool> isFavorite(String userId, String produitId);
}
EOF
echo "→ lib/domain/repositories/i_favorite_repository.dart créé."

cat > lib/domain/repositories/i_user_repository.dart << 'EOF'
import '../entities/utilisateur.dart';
import '../enums/user_role.dart';

/// Gestion des utilisateurs (hors authentification), utilisée
/// principalement par les écrans Admin / Super Admin pour lister,
/// activer/désactiver des comptes, et par les écrans qui ont besoin
/// d'afficher les informations d'un autre utilisateur (ex: nom du
/// vendeur sur une fiche produit).
abstract class IUserRepository {
  Future<List<Utilisateur>> getAll();
  Future<Utilisateur?> getById(String id);
  Future<List<Utilisateur>> getByRole(UserRole role);
  Future<void> save(Utilisateur utilisateur);
  Future<void> toggleActif(String userId, bool estActif);
}
EOF
echo "→ lib/domain/repositories/i_user_repository.dart créé."

echo ""
echo "→ 12 interfaces de repository créées dans lib/domain/repositories."
echo ""

# ============================================================================
# 4. IMPLÉMENTATIONS LOCALES (lib/data/repositories/local)
# ============================================================================

cat > lib/data/repositories/local/local_auth_repository.dart << 'EOF'
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/utilisateur_model.dart';

/// Implémentation locale de l'authentification, basée sur Hive.
///
/// Les mots de passe ne sont jamais comparés en clair : on compare
/// leur hash SHA-256, exactement comme le ferait un futur backend.
/// Cela permet de garder un code de comparaison identique, qu'on soit
/// en mode local ou en mode API.
class LocalAuthRepository implements IAuthRepository {
  final LocalJsonStore<UtilisateurModel> _store;
  final LocalJsonStore<String> _sessionStore;

  LocalAuthRepository()
      : _store = LocalJsonStore<UtilisateurModel>(
          boxName: StorageKeys.usersBox,
          toJson: (m) => m.toJson(),
          fromJson: UtilisateurModel.fromJson,
          idOf: (m) => m.id,
        ),
        _sessionStore = LocalJsonStore<String>(
          boxName: StorageKeys.sessionBox,
          toJson: (s) => {'value': s},
          fromJson: (json) => json['value'] as String,
          idOf: (s) => StorageKeys.secureCurrentUserIdKey,
        );

  static String hashPassword(String motDePasse) {
    final bytes = utf8.encode(motDePasse);
    return sha256.convert(bytes).toString();
  }

  @override
  Future<Utilisateur?> login({
    required String telephone,
    required String motDePasse,
  }) async {
    final tousLesUtilisateurs = await _store.getAll();
    final hash = hashPassword(motDePasse);

    UtilisateurModel? trouve;
    for (final u in tousLesUtilisateurs) {
      if (u.telephone == telephone && u.motDePasseHash == hash) {
        trouve = u;
        break;
      }
    }

    if (trouve == null) {
      throw const AuthException('Numéro ou mot de passe incorrect.');
    }

    await _sessionStore.save(trouve.id);
    return trouve.toEntity();
  }

  @override
  Future<Utilisateur> register(Utilisateur utilisateur, String motDePasse) async {
    final existants = await _store.getAll();
    final dejaUtilise = existants.any((u) => u.telephone == utilisateur.telephone);
    if (dejaUtilise) {
      throw const BusinessRuleException('Ce numéro est déjà utilisé.');
    }

    final model = UtilisateurModel.fromEntity(
      utilisateur.copyWith(motDePasseHash: hashPassword(motDePasse)),
    );
    await _store.save(model);
    await _sessionStore.save(model.id);
    return model.toEntity();
  }

  @override
  Future<void> logout() async {
    await _sessionStore.delete(StorageKeys.secureCurrentUserIdKey);
  }

  @override
  Future<Utilisateur?> getCurrentUser() async {
    final userId = await _sessionStore.getById(StorageKeys.secureCurrentUserIdKey);
    if (userId == null) return null;
    final model = await _store.getById(userId);
    return model?.toEntity();
  }

  @override
  Future<List<Utilisateur>> getDemoAccounts() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  /// Connecte directement un compte de démonstration par son
  /// identifiant, sans vérification de mot de passe. Utilisé
  /// exclusivement par l'écran de sélection de compte démo.
  @override
  Future<Utilisateur?> loginAsDemoAccount(String userId) async {
    final model = await _store.getById(userId);
    if (model == null) return null;
    await _sessionStore.save(model.id);
    return model.toEntity();
  }
}
EOF
echo "→ lib/data/repositories/local/local_auth_repository.dart créé."

cat > lib/data/repositories/local/local_product_repository.dart << 'EOF'
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/repositories/i_product_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/produit_model.dart';

class LocalProductRepository implements IProductRepository {
  final LocalJsonStore<ProduitModel> _store = LocalJsonStore<ProduitModel>(
    boxName: StorageKeys.productsBox,
    toJson: (m) => m.toJson(),
    fromJson: ProduitModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Produit>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Produit?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Produit>> getEnVente({String? categorieId, String? recherche}) async {
    final all = await getAll();
    return all.where((p) {
      final estEnVente = p.statut == ProductStatus.enVente;
      final matchCategorie = categorieId == null || p.categorieId == categorieId;
      final matchRecherche = recherche == null ||
          recherche.isEmpty ||
          p.titre.toLowerCase().contains(recherche.toLowerCase());
      return estEnVente && matchCategorie && matchRecherche;
    }).toList();
  }

  @override
  Future<List<Produit>> getByVendeur(String vendeurId) async {
    final all = await getAll();
    return all.where((p) => p.vendeurId == vendeurId).toList();
  }

  @override
  Future<List<Produit>> getByAgent(String agentId) async {
    final all = await getAll();
    return all.where((p) => p.agentId == agentId).toList();
  }

  @override
  Future<List<Produit>> getByStatut(ProductStatus statut) async {
    final all = await getAll();
    return all.where((p) => p.statut == statut).toList();
  }

  @override
  Future<void> save(Produit produit) async {
    await _store.save(ProduitModel.fromEntity(produit));
  }

  @override
  Future<void> updateStatut(String produitId, ProductStatus nouveauStatut) async {
    final existant = await getById(produitId);
    if (existant == null) return;
    await save(existant.copyWith(statut: nouveauStatut));
  }

  @override
  Future<void> delete(String id) async {
    await _store.delete(id);
  }
}
EOF
echo "→ lib/data/repositories/local/local_product_repository.dart créé."

cat > lib/data/repositories/local/local_order_repository.dart << 'EOF'
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/repositories/i_order_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/commande_model.dart';

class LocalOrderRepository implements IOrderRepository {
  final LocalJsonStore<CommandeModel> _store = LocalJsonStore<CommandeModel>(
    boxName: StorageKeys.ordersBox,
    toJson: (m) => m.toJson(),
    fromJson: CommandeModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Commande>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Commande?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Commande>> getByAcheteur(String acheteurId) async {
    final all = await getAll();
    return all.where((c) => c.acheteurId == acheteurId).toList();
  }

  @override
  Future<void> save(Commande commande) async {
    await _store.save(CommandeModel.fromEntity(commande));
  }

  @override
  Future<void> updateStatut(String commandeId, OrderStatus nouveauStatut) async {
    final existant = await getById(commandeId);
    if (existant == null) return;
    await save(existant.copyWith(statut: nouveauStatut));
  }
}
EOF
echo "→ lib/data/repositories/local/local_order_repository.dart créé."

cat > lib/data/repositories/local/local_payment_repository.dart << 'EOF'
import '../../../domain/entities/paiement.dart';
import '../../../domain/repositories/i_payment_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/paiement_model.dart';

class LocalPaymentRepository implements IPaymentRepository {
  final LocalJsonStore<PaiementModel> _store = LocalJsonStore<PaiementModel>(
    boxName: 'payments_box',
    toJson: (m) => m.toJson(),
    fromJson: PaiementModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Paiement>> getByCommande(String commandeId) async {
    final all = await _store.getAll();
    return all
        .where((m) => m.commandeId == commandeId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<void> save(Paiement paiement) async {
    await _store.save(PaiementModel.fromEntity(paiement));
  }
}
EOF
echo "→ lib/data/repositories/local/local_payment_repository.dart créé."

cat > lib/data/repositories/local/local_seller_request_repository.dart << 'EOF'
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/demande_vendeur.dart';
import '../../../domain/repositories/i_seller_request_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/demande_vendeur_model.dart';

class LocalSellerRequestRepository implements ISellerRequestRepository {
  final LocalJsonStore<DemandeVendeurModel> _store =
      LocalJsonStore<DemandeVendeurModel>(
    boxName: StorageKeys.sellerRequestsBox,
    toJson: (m) => m.toJson(),
    fromJson: DemandeVendeurModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<DemandeVendeur>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<DemandeVendeur?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<DemandeVendeur>> getByVendeur(String vendeurId) async {
    final all = await getAll();
    return all.where((d) => d.vendeurId == vendeurId).toList();
  }

  @override
  Future<void> save(DemandeVendeur demande) async {
    await _store.save(DemandeVendeurModel.fromEntity(demande));
  }

  @override
  Future<void> delete(String id) async {
    await _store.delete(id);
  }
}
EOF
echo "→ lib/data/repositories/local/local_seller_request_repository.dart créé."

cat > lib/data/repositories/local/local_mission_repository.dart << 'EOF'
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/mission.dart';
import '../../../domain/repositories/i_mission_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/mission_model.dart';

class LocalMissionRepository implements IMissionRepository {
  final LocalJsonStore<MissionModel> _store = LocalJsonStore<MissionModel>(
    boxName: StorageKeys.missionsBox,
    toJson: (m) => m.toJson(),
    fromJson: MissionModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Mission>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Mission?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Mission>> getByAgent(String agentId) async {
    final all = await getAll();
    return all.where((m) => m.agentId == agentId).toList();
  }

  @override
  Future<void> save(Mission mission) async {
    await _store.save(MissionModel.fromEntity(mission));
  }
}
EOF
echo "→ lib/data/repositories/local/local_mission_repository.dart créé."

cat > lib/data/repositories/local/local_dispute_repository.dart << 'EOF'
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/litige.dart';
import '../../../domain/repositories/i_dispute_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/litige_model.dart';

class LocalDisputeRepository implements IDisputeRepository {
  final LocalJsonStore<LitigeModel> _store = LocalJsonStore<LitigeModel>(
    boxName: StorageKeys.disputesBox,
    toJson: (m) => m.toJson(),
    fromJson: LitigeModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Litige>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Litige?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(Litige litige) async {
    await _store.save(LitigeModel.fromEntity(litige));
  }
}
EOF
echo "→ lib/data/repositories/local/local_dispute_repository.dart créé."

cat > lib/data/repositories/local/local_notification_repository.dart << 'EOF'
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/repositories/i_notification_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/notification_model.dart';

class LocalNotificationRepository implements INotificationRepository {
  final LocalJsonStore<NotificationModel> _store =
      LocalJsonStore<NotificationModel>(
    boxName: StorageKeys.notificationsBox,
    toJson: (m) => m.toJson(),
    fromJson: NotificationModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<NotificationEntity>> getByDestinataire(String userId) async {
    final all = await _store.getAll();
    final filtered = all.where((m) => m.destinataireId == userId).toList();
    filtered.sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));
    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(NotificationEntity notification) async {
    await _store.save(NotificationModel.fromEntity(notification));
  }

  @override
  Future<void> marquerCommeLue(String notificationId) async {
    final model = await _store.getById(notificationId);
    if (model == null) return;
    final entity = model.toEntity().copyWith(estLue: true);
    await save(entity);
  }

  @override
  Future<int> compterNonLues(String userId) async {
    final notifications = await getByDestinataire(userId);
    return notifications.where((n) => !n.estLue).length;
  }
}
EOF
echo "→ lib/data/repositories/local/local_notification_repository.dart créé."

cat > lib/data/repositories/local/local_message_repository.dart << 'EOF'
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/i_message_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';

class LocalMessageRepository implements IMessageRepository {
  final LocalJsonStore<ConversationModel> _conversationStore =
      LocalJsonStore<ConversationModel>(
    boxName: 'conversations_box',
    toJson: (m) => m.toJson(),
    fromJson: ConversationModel.fromJson,
    idOf: (m) => m.id,
  );

  final LocalJsonStore<MessageModel> _messageStore = LocalJsonStore<MessageModel>(
    boxName: StorageKeys.messagesBox,
    toJson: (m) => m.toJson(),
    fromJson: MessageModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Conversation>> getConversations(String userId) async {
    final all = await _conversationStore.getAll();
    final filtered = all.where((c) => c.participantIds.contains(userId)).toList();
    filtered.sort((a, b) => b.dateDernierMessage.compareTo(a.dateDernierMessage));
    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final all = await _messageStore.getAll();
    final filtered = all.where((m) => m.conversationId == conversationId).toList();
    filtered.sort((a, b) => a.dateEnvoi.compareTo(b.dateEnvoi));
    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> envoyerMessage(Message message) async {
    await _messageStore.save(MessageModel.fromEntity(message));
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    await _conversationStore.save(ConversationModel.fromEntity(conversation));
  }
}
EOF
echo "→ lib/data/repositories/local/local_message_repository.dart créé."

cat > lib/data/repositories/local/local_category_repository.dart << 'EOF'
import '../../../domain/entities/categorie.dart';
import '../../../domain/repositories/i_category_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/categorie_model.dart';

class LocalCategoryRepository implements ICategoryRepository {
  final LocalJsonStore<CategorieModel> _store = LocalJsonStore<CategorieModel>(
    boxName: 'categories_box',
    toJson: (m) => m.toJson(),
    fromJson: CategorieModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Categorie>> getAll() async {
    final all = await _store.getAll();
    final entities = all.map((m) => m.toEntity()).toList();
    entities.sort((a, b) => a.ordreAffichage.compareTo(b.ordreAffichage));
    return entities;
  }

  @override
  Future<void> save(Categorie categorie) async {
    await _store.save(CategorieModel.fromEntity(categorie));
  }

  @override
  Future<void> delete(String id) async {
    await _store.delete(id);
  }
}
EOF
echo "→ lib/data/repositories/local/local_category_repository.dart créé."

cat > lib/data/repositories/local/local_favorite_repository.dart << 'EOF'
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
EOF
echo "→ lib/data/repositories/local/local_favorite_repository.dart créé."

cat > lib/data/repositories/local/local_user_repository.dart << 'EOF'
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/enums/user_role.dart';
import '../../../domain/repositories/i_user_repository.dart';
import '../../local/datasources/local_json_store.dart';
import '../../models/utilisateur_model.dart';

class LocalUserRepository implements IUserRepository {
  final LocalJsonStore<UtilisateurModel> _store = LocalJsonStore<UtilisateurModel>(
    boxName: StorageKeys.usersBox,
    toJson: (m) => m.toJson(),
    fromJson: UtilisateurModel.fromJson,
    idOf: (m) => m.id,
  );

  @override
  Future<List<Utilisateur>> getAll() async {
    final all = await _store.getAll();
    return all.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Utilisateur?> getById(String id) async {
    final model = await _store.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Utilisateur>> getByRole(UserRole role) async {
    final all = await getAll();
    return all.where((u) => u.role == role).toList();
  }

  @override
  Future<void> save(Utilisateur utilisateur) async {
    await _store.save(UtilisateurModel.fromEntity(utilisateur));
  }

  @override
  Future<void> toggleActif(String userId, bool estActif) async {
    final existant = await getById(userId);
    if (existant == null) return;
    await save(existant.copyWith(estActif: estActif));
  }
}
EOF
echo "→ lib/data/repositories/local/local_user_repository.dart créé."

echo ""
echo "============================================================"
echo "  ✔ Script 05 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • HiveService (initialisation + ouverture de 14 box)"
echo "  • LocalJsonStore (brique générique de stockage JSON)"
echo "  • 12 interfaces de repository (lib/domain/repositories)"
echo "  • 12 implémentations locales Hive (lib/data/repositories/local)"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 06 : les"
echo "  données de démonstration (comptes test, catégories, produits"
echo "  d'exemple) insérées automatiquement au premier lancement."
echo ""

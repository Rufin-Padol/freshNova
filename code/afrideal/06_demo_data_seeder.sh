#!/bin/bash
# ============================================================================
# SCRIPT 06 — Données de démonstration (Seeder)
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   Crée lib/data/local/seed/demo_data_seeder.dart, une classe qui
#   insère automatiquement, au tout premier lancement de l'application
#   (et uniquement si les box Hive sont vides), un jeu de données
#   cohérent permettant de démontrer IMMÉDIATEMENT toutes les
#   fonctionnalités, sans aucune configuration manuelle.
#
# CE QUI EST INSÉRÉ :
#   • 5 comptes de démonstration (un par rôle), conformes au choix
#     validé : connexion directe par sélection, sans mot de passe à
#     retenir.
#   • 5 catégories de produits (Électronique, Mode, Maison, Véhicules,
#     Autres), reprenant exactement celles visibles sur les maquettes.
#   • 8 produits couvrant DIFFÉRENTS statuts du cycle de vie (Soumis,
#     Mission assignée, En vérification, En vente, Réservé, Livré...)
#     pour que chaque écran de chaque rôle ait quelque chose à
#     afficher dès le premier lancement.
#   • 2 commandes (une payée en livraison, une livrée) liées aux bons
#     produits et au bon acheteur.
#   • 1 demande vendeur en attente et 1 mission de collecte assignée,
#     pour démontrer le parcours Agent terrain.
#   • Quelques notifications et une conversation de support, pour que
#     les écrans Messages/Notifications ne soient pas vides non plus.
#
# IMPORTANT — IDENTIFIANTS FIXES (pas de génération aléatoire) :
#   Tous les identifiants de ce jeu de données sont des chaînes FIXES
#   (ex: 'demo-user-acheteur'), et non générés par uuid(). Cela permet
#   de les RÉFÉRENCER de façon stable dans tout le reste du code (par
#   exemple, pour pré-remplir un écran de test) et de les régénérer de
#   façon identique à chaque réinitialisation des données.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 06_demo_data_seeder.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 06 terminé avec succès."
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 06/14 : Données de démonstration"
echo "============================================================"

if [ ! -d "lib/data/repositories/local" ]; then
  echo "ERREUR : lib/data/repositories/local introuvable. Avez-vous exécuté le script 05 ?"
  exit 1
fi

mkdir -p lib/data/local/seed

cat > lib/data/local/seed/demo_data_seeder.dart << 'EOF'
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/categorie.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/demande_vendeur.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/mission.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/entities/paiement.dart';
import '../../../domain/entities/photo.dart';
import '../../../domain/entities/produit.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../domain/enums/dispute_status.dart';
import '../../../domain/enums/mission_status.dart';
import '../../../domain/enums/notification_type.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/enums/payment_status.dart';
import '../../../domain/enums/photo_type.dart';
import '../../../domain/enums/product_status.dart';
import '../../../domain/enums/seller_request_status.dart';
import '../../../domain/enums/user_role.dart';
import '../../repositories/local/local_auth_repository.dart';
import '../../repositories/local/local_category_repository.dart';
import '../../repositories/local/local_message_repository.dart';
import '../../repositories/local/local_mission_repository.dart';
import '../../repositories/local/local_notification_repository.dart';
import '../../repositories/local/local_order_repository.dart';
import '../../repositories/local/local_payment_repository.dart';
import '../../repositories/local/local_product_repository.dart';
import '../../repositories/local/local_seller_request_repository.dart';
import 'datasources_box_check.dart';

/// Identifiants fixes des comptes et entités de démonstration.
///
/// Centraliser ces identifiants ici (plutôt que de les coder en dur à
/// plusieurs endroits) permet de les référencer facilement ailleurs
/// dans le code si besoin, et garantit qu'ils restent identiques à
/// chaque réinitialisation des données.
class DemoIds {
  DemoIds._();

  static const acheteurId = 'demo-user-acheteur';
  static const vendeurId = 'demo-user-vendeur';
  static const agentId = 'demo-user-agent';
  static const adminId = 'demo-user-admin';
  static const superAdminId = 'demo-user-super-admin';
  static const supportId = 'demo-user-support';

  static const catElectronique = 'cat-electronique';
  static const catMode = 'cat-mode';
  static const catMaison = 'cat-maison';
  static const catVehicules = 'cat-vehicules';
  static const catAutres = 'cat-autres';
}

/// Insère le jeu de données de démonstration complet, une seule fois,
/// au premier lancement de l'application.
///
/// Appelée depuis main.dart juste après [HiveService.init]. La méthode
/// [seedIfNeeded] vérifie elle-même si les données existent déjà avant
/// d'insérer quoi que ce soit, donc il est sans danger de l'appeler à
/// chaque démarrage de l'application.
class DemoDataSeeder {
  static Future<void> seedIfNeeded() async {
    final dejaInitialise = await DemoSeedCheck.isAlreadySeeded();
    if (dejaInitialise) return;

    await _seedUsers();
    await _seedCategories();
    final produitIds = await _seedProducts();
    await _seedOrdersAndPayments(produitIds);
    await _seedSellerRequestAndMission();
    await _seedNotificationsAndMessages();

    await DemoSeedCheck.markAsSeeded();
  }

  // ──────────────────────────────────────────────────────────────
  // Comptes de démonstration (un par rôle)
  // ──────────────────────────────────────────────────────────────
  static Future<void> _seedUsers() async {
    final authRepo = LocalAuthRepository();
    final hash = LocalAuthRepository.hashPassword('demo1234');
    final maintenant = DateTime.now();

    final utilisateurs = [
      Utilisateur(
        id: DemoIds.acheteurId,
        nom: 'Mballa',
        prenom: 'Marie',
        telephone: '670000001',
        motDePasseHash: hash,
        role: UserRole.acheteur,
        ville: 'Douala',
        dateInscription: maintenant.subtract(const Duration(days: 90)),
      ),
      Utilisateur(
        id: DemoIds.vendeurId,
        nom: 'Tagne',
        prenom: 'Michel',
        telephone: '670000002',
        motDePasseHash: hash,
        role: UserRole.vendeur,
        ville: 'Douala',
        noteVendeur: 4.8,
        dateInscription: maintenant.subtract(const Duration(days: 120)),
      ),
      Utilisateur(
        id: DemoIds.agentId,
        nom: 'Nkeng',
        prenom: 'Paul',
        telephone: '670000003',
        motDePasseHash: hash,
        role: UserRole.agentTerrain,
        ville: 'Douala',
        dateInscription: maintenant.subtract(const Duration(days: 200)),
      ),
      Utilisateur(
        id: DemoIds.adminId,
        nom: 'Fotso',
        prenom: 'Sandrine',
        telephone: '670000004',
        motDePasseHash: hash,
        role: UserRole.admin,
        ville: 'Douala',
        dateInscription: maintenant.subtract(const Duration(days: 300)),
      ),
      Utilisateur(
        id: DemoIds.superAdminId,
        nom: 'Eyenga',
        prenom: 'Directeur',
        telephone: '670000005',
        motDePasseHash: hash,
        role: UserRole.superAdmin,
        ville: 'Douala',
        dateInscription: maintenant.subtract(const Duration(days: 400)),
      ),
      Utilisateur(
        id: DemoIds.supportId,
        nom: 'AfriDeal',
        prenom: 'Support',
        telephone: '670000000',
        motDePasseHash: hash,
        role: UserRole.admin,
        dateInscription: maintenant.subtract(const Duration(days: 400)),
      ),
    ];

    for (final u in utilisateurs) {
      await authRepo.register(u, 'demo1234');
    }
    // Déconnecte automatiquement après le seed : on ne veut pas qu'un
    // compte soit connecté par défaut, l'utilisateur doit choisir.
    await authRepo.logout();
  }

  // ──────────────────────────────────────────────────────────────
  // Catégories (identiques aux maquettes AfriDeal)
  // ──────────────────────────────────────────────────────────────
  static Future<void> _seedCategories() async {
    final repo = LocalCategoryRepository();
    final categories = [
      const Categorie(
        id: DemoIds.catElectronique,
        nom: 'Électronique',
        iconeAsset: 'assets/icons/categorie_electronique.svg',
        ordreAffichage: 0,
      ),
      const Categorie(
        id: DemoIds.catMode,
        nom: 'Mode',
        iconeAsset: 'assets/icons/categorie_mode.svg',
        ordreAffichage: 1,
      ),
      const Categorie(
        id: DemoIds.catMaison,
        nom: 'Maison',
        iconeAsset: 'assets/icons/categorie_maison.svg',
        ordreAffichage: 2,
      ),
      const Categorie(
        id: DemoIds.catVehicules,
        nom: 'Véhicules',
        iconeAsset: 'assets/icons/categorie_vehicules.svg',
        ordreAffichage: 3,
      ),
      const Categorie(
        id: DemoIds.catAutres,
        nom: 'Autres',
        iconeAsset: 'assets/icons/categorie_autres.svg',
        ordreAffichage: 4,
      ),
    ];
    for (final c in categories) {
      await repo.save(c);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Produits — couvrant différents statuts du cycle de vie
  // ──────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _seedProducts() async {
    final repo = LocalProductRepository();
    final maintenant = DateTime.now();

    Photo photoOfficielle(String id, String url) => Photo(
          id: id,
          url: url,
          type: PhotoType.officielleAgent,
          estOfficielle: true,
          horodatage: maintenant.subtract(const Duration(days: 2)),
        );

    final produits = <Produit>[
      // 1. EN VENTE — iPhone 12, visible immédiatement dans la boutique
      Produit(
        id: 'demo-prod-iphone12',
        titre: 'iPhone 12 64GB',
        description:
            'iPhone 12 64GB en parfait état. Toujours utilisé avec coque et '
            'protection d\'écran. Batterie à 90%. Vendu avec chargeur.',
        prix: 250000,
        etat: ProductCondition.commeNeuf,
        statut: ProductStatus.enVente,
        categorieId: DemoIds.catElectronique,
        dateCreation: maintenant.subtract(const Duration(days: 5)),
        vendeurId: DemoIds.vendeurId,
        agentId: DemoIds.agentId,
        localisation: 'Douala, Akwa',
        tauxCommission: 12,
        photos: [
          photoOfficielle('photo-iphone12-1',
              'https://images.unsplash.com/photo-1611472173362-3f53dbd65d80'),
        ],
      ),

      // 2. EN VENTE — Chaise scandinave
      Produit(
        id: 'demo-prod-chaise',
        titre: 'Chaise scandinave',
        description:
            'Chaise de style scandinave en bois clair, assise confortable. '
            'Idéale pour bureau ou salle à manger.',
        prix: 45000,
        etat: ProductCondition.bonEtat,
        statut: ProductStatus.enVente,
        categorieId: DemoIds.catMaison,
        dateCreation: maintenant.subtract(const Duration(days: 8)),
        vendeurId: DemoIds.vendeurId,
        agentId: DemoIds.agentId,
        localisation: 'Douala, Bonapriso',
        tauxCommission: 10,
        photos: [
          photoOfficielle('photo-chaise-1',
              'https://images.unsplash.com/photo-1503602642458-232111445657'),
        ],
      ),

      // 3. EN VENTE — Casque Sony
      Produit(
        id: 'demo-prod-casque',
        titre: 'Casque Sony WH-1000XM4',
        description:
            'Casque à réduction de bruit, excellent état, livré avec étui '
            'et câble de charge.',
        prix: 35000,
        etat: ProductCondition.bonEtat,
        statut: ProductStatus.enVente,
        categorieId: DemoIds.catElectronique,
        dateCreation: maintenant.subtract(const Duration(days: 3)),
        vendeurId: DemoIds.vendeurId,
        agentId: DemoIds.agentId,
        localisation: 'Douala, Bonanjo',
        tauxCommission: 12,
        photos: [
          photoOfficielle('photo-casque-1',
              'https://images.unsplash.com/photo-1505740420928-5e560c06d30e'),
        ],
      ),

      // 4. SOUMIS — produit fraîchement soumis, aucun agent assigné
      Produit(
        id: 'demo-prod-soumis',
        titre: 'Sac à main en cuir',
        description: 'Sac à main en cuir véritable, porté quelques fois.',
        prix: 18000,
        etat: ProductCondition.bonEtat,
        statut: ProductStatus.soumis,
        categorieId: DemoIds.catMode,
        dateCreation: maintenant.subtract(const Duration(hours: 12)),
        vendeurId: DemoIds.vendeurId,
        localisation: 'Douala, Deido',
        tauxCommission: 15,
      ),

      // 5. MISSION ASSIGNÉE
      Produit(
        id: 'demo-prod-mission',
        titre: 'Téléviseur Samsung 43"',
        description: 'Téléviseur Samsung 43 pouces, télécommande incluse.',
        prix: 95000,
        etat: ProductCondition.bonEtat,
        statut: ProductStatus.missionAssignee,
        categorieId: DemoIds.catElectronique,
        dateCreation: maintenant.subtract(const Duration(hours: 6)),
        vendeurId: DemoIds.vendeurId,
        agentId: DemoIds.agentId,
        localisation: 'Douala, Logpom',
        tauxCommission: 10,
      ),

      // 6. EN VÉRIFICATION
      Produit(
        id: 'demo-prod-verification',
        titre: 'Montre connectée',
        description: 'Montre connectée avec suivi d\'activité et notifications.',
        prix: 28000,
        etat: ProductCondition.commeNeuf,
        statut: ProductStatus.enVerification,
        categorieId: DemoIds.catElectronique,
        dateCreation: maintenant.subtract(const Duration(hours: 2)),
        vendeurId: DemoIds.vendeurId,
        agentId: DemoIds.agentId,
        localisation: 'Douala, Makepe',
        tauxCommission: 12,
      ),

      // 7. RÉSERVÉ — pour la commande en cours de livraison
      Produit(
        id: 'demo-prod-reserve',
        titre: 'Vélo VTT',
        description: 'VTT en bon état, pneus récemment changés.',
        prix: 60000,
        etat: ProductCondition.bonEtat,
        statut: ProductStatus.reserve,
        categorieId: DemoIds.catAutres,
        dateCreation: maintenant.subtract(const Duration(days: 4)),
        vendeurId: DemoIds.vendeurId,
        agentId: DemoIds.agentId,
        localisation: 'Douala, Bonamoussadi',
        tauxCommission: 10,
        photos: [
          photoOfficielle('photo-velo-1',
              'https://images.unsplash.com/photo-1485965120184-e220f721d03e'),
        ],
      ),

      // 8. LIVRÉ — pour l'historique de commandes
      Produit(
        id: 'demo-prod-livre',
        titre: 'Enceinte Bluetooth JBL',
        description: 'Enceinte portable JBL, autonomie 10h.',
        prix: 22000,
        etat: ProductCondition.bonEtat,
        statut: ProductStatus.livre,
        categorieId: DemoIds.catElectronique,
        dateCreation: maintenant.subtract(const Duration(days: 15)),
        vendeurId: DemoIds.vendeurId,
        agentId: DemoIds.agentId,
        localisation: 'Douala, Akwa',
        tauxCommission: 12,
        photos: [
          photoOfficielle('photo-jbl-1',
              'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1'),
        ],
      ),
    ];

    for (final p in produits) {
      await repo.save(p);
    }

    return {for (final p in produits) p.id: p.id};
  }

  // ──────────────────────────────────────────────────────────────
  // Commandes et paiements
  // ──────────────────────────────────────────────────────────────
  static Future<void> _seedOrdersAndPayments(Map<String, String> produitIds) async {
    final orderRepo = LocalOrderRepository();
    final paymentRepo = LocalPaymentRepository();
    final maintenant = DateTime.now();

    final commandeEnLivraison = Commande(
      id: 'demo-cmd-1',
      reference: Commande.genererReference(1),
      montantTotal: 60000,
      statut: OrderStatus.enLivraison,
      dateCommande: maintenant.subtract(const Duration(hours: 5)),
      modeLivraison: DeliveryMode.livraison,
      adresseLivraison: 'Rue de la Joie, Bonamoussadi, Douala',
      acheteurId: DemoIds.acheteurId,
      produitId: 'demo-prod-reserve',
    );

    final commandeLivree = Commande(
      id: 'demo-cmd-2',
      reference: Commande.genererReference(2),
      montantTotal: 22000,
      statut: OrderStatus.livree,
      dateCommande: maintenant.subtract(const Duration(days: 14)),
      modeLivraison: DeliveryMode.livraison,
      adresseLivraison: 'Rue de la Joie, Bonamoussadi, Douala',
      acheteurId: DemoIds.acheteurId,
      produitId: 'demo-prod-livre',
    );

    await orderRepo.save(commandeEnLivraison);
    await orderRepo.save(commandeLivree);

    await paymentRepo.save(Paiement(
      id: 'demo-pay-1',
      montant: 60000,
      methode: PaymentMethod.orangeMoney,
      reference: 'OM-2026-0001',
      statut: PaymentStatus.valide,
      dateHeure: maintenant.subtract(const Duration(hours: 5)),
      numeroPaieur: '670000001',
      commandeId: 'demo-cmd-1',
    ));

    await paymentRepo.save(Paiement(
      id: 'demo-pay-2',
      montant: 22000,
      methode: PaymentMethod.mtnMomo,
      reference: 'MTN-2026-0002',
      statut: PaymentStatus.valide,
      dateHeure: maintenant.subtract(const Duration(days: 14)),
      numeroPaieur: '670000001',
      commandeId: 'demo-cmd-2',
    ));
  }

  // ──────────────────────────────────────────────────────────────
  // Demande vendeur en attente + mission de collecte assignée
  // (pour démontrer le parcours Agent terrain dès le premier lancement)
  // ──────────────────────────────────────────────────────────────
  static Future<void> _seedSellerRequestAndMission() async {
    final requestRepo = LocalSellerRequestRepository();
    final missionRepo = LocalMissionRepository();
    final maintenant = DateTime.now();

    await requestRepo.save(DemandeVendeur(
      id: 'demo-req-1',
      statut: SellerRequestStatus.agentAssigne,
      adresse: 'Carrefour Logpom, Douala',
      disponibilite: 'Tous les jours après 14h',
      contactVendeur: '670000002',
      zone: 'Douala 5ème',
      dateCreation: maintenant.subtract(const Duration(hours: 8)),
      vendeurId: DemoIds.vendeurId,
      typeProduitSouhaite: 'Téléviseur Samsung 43"',
      quantite: 1,
      descriptionInitiale: 'Téléviseur en bon état, peu utilisé.',
      prixSouhaite: 95000,
      missionId: 'demo-mission-1',
    ));

    await missionRepo.save(Mission(
      id: 'demo-mission-1',
      type: MissionType.collecte,
      statut: MissionStatus.assignee,
      dateHeure: maintenant.add(const Duration(hours: 3)),
      agentId: DemoIds.agentId,
      referenceId: 'demo-req-1',
      latitude: 4.0511,
      longitude: 9.7679,
    ));
  }

  // ──────────────────────────────────────────────────────────────
  // Notifications et conversation de support
  // ──────────────────────────────────────────────────────────────
  static Future<void> _seedNotificationsAndMessages() async {
    final notificationRepo = LocalNotificationRepository();
    final messageRepo = LocalMessageRepository();
    final maintenant = DateTime.now();

    await notificationRepo.save(NotificationEntity(
      id: 'demo-notif-1',
      message: 'Votre commande #${Commande.genererReference(1)} est en cours de livraison.',
      type: NotificationType.commande,
      dateEnvoi: maintenant.subtract(const Duration(hours: 5)),
      destinataireId: DemoIds.acheteurId,
      referenceId: 'demo-cmd-1',
    ));

    await notificationRepo.save(NotificationEntity(
      id: 'demo-notif-2',
      message: 'Un agent a été assigné pour la collecte de votre téléviseur.',
      type: NotificationType.mission,
      dateEnvoi: maintenant.subtract(const Duration(hours: 6)),
      destinataireId: DemoIds.vendeurId,
      referenceId: 'demo-req-1',
    ));

    await notificationRepo.save(NotificationEntity(
      id: 'demo-notif-3',
      message: 'Nouvelle mission de collecte assignée à Douala 5ème.',
      type: NotificationType.mission,
      dateEnvoi: maintenant.subtract(const Duration(hours: 6)),
      destinataireId: DemoIds.agentId,
      referenceId: 'demo-mission-1',
      estLue: true,
    ));

    final conversationSupport = Conversation(
      id: 'demo-conv-support',
      participantIds: const [DemoIds.acheteurId, DemoIds.supportId],
      dernierMessage: 'Votre transaction a été sécurisée.',
      dateDernierMessage: maintenant.subtract(const Duration(days: 6)),
      estSupport: true,
    );
    await messageRepo.saveConversation(conversationSupport);

    await messageRepo.envoyerMessage(Message(
      id: 'demo-msg-1',
      conversationId: 'demo-conv-support',
      expediteurId: DemoIds.supportId,
      contenu: 'Bonjour Marie, bienvenue sur AfriDeal !',
      dateEnvoi: maintenant.subtract(const Duration(days: 6, hours: 1)),
      estLu: true,
    ));

    await messageRepo.envoyerMessage(Message(
      id: 'demo-msg-2',
      conversationId: 'demo-conv-support',
      expediteurId: DemoIds.supportId,
      contenu: 'Votre transaction a été sécurisée.',
      dateEnvoi: maintenant.subtract(const Duration(days: 6)),
      estLu: true,
    ));
  }
}
EOF
echo "→ lib/data/local/seed/demo_data_seeder.dart créé."

# ============================================================================
# 2. UTILITAIRE : vérification "déjà initialisé"
# ============================================================================
cat > lib/data/local/seed/datasources_box_check.dart << 'EOF'
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Petit utilitaire qui détermine si les données de démonstration ont
/// déjà été insérées, pour ne jamais les dupliquer à chaque démarrage
/// de l'application.
///
/// Utilise une box Hive dédiée et minimaliste plutôt que de vérifier
/// "users_box est-elle vide ?", car cette dernière approche poserait
/// problème si l'utilisateur supprime manuellement tous ses comptes :
/// le seed se relancerait alors qu'on ne le souhaite pas forcément.
class DemoSeedCheck {
  DemoSeedCheck._();

  static const String _boxName = 'app_meta_box';
  static const String _seedKey = 'demo_data_seeded';

  static Future<bool> isAlreadySeeded() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    final box = Hive.box<String>(_boxName);
    return box.get(_seedKey) == 'true';
  }

  static Future<void> markAsSeeded() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    final box = Hive.box<String>(_boxName);
    await box.put(_seedKey, 'true');
  }

  /// Permet de forcer une réinitialisation complète des données de
  /// démonstration (utilisé par le bouton "Réinitialiser" dans les
  /// réglages, voir script des écrans de profil).
  static Future<void> resetSeedFlag() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    final box = Hive.box<String>(_boxName);
    await box.delete(_seedKey);
  }
}
EOF
echo "→ lib/data/local/seed/datasources_box_check.dart créé."

echo ""
echo "============================================================"
echo "  ✔ Script 06 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • DemoDataSeeder : insère automatiquement au premier lancement"
echo "    6 comptes (Acheteur, Vendeur, Agent, Admin, Super Admin,"
echo "    Support), 5 catégories, 8 produits à différents statuts du"
echo "    cycle de vie, 2 commandes avec paiements, 1 demande vendeur"
echo "    avec mission assignée, et des notifications/messages."
echo "  • DemoSeedCheck : évite toute duplication des données au"
echo "    redémarrage, avec une option de réinitialisation manuelle."
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 07 : les"
echo "  widgets partagés réutilisables (boutons, cartes, champs de"
echo "  saisie, illustrations SVG) — la base visuelle de tous les"
echo "  écrans à venir."
echo ""

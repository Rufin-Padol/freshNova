#!/bin/bash
# ============================================================================
# SCRIPT 03 — Enums métier et Entités du domaine
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   1. lib/domain/enums/      → toutes les énumérations métier (rôles,
#      statuts produit, statuts commande, statuts paiement, statuts
#      mission, statuts demande vendeur, statuts litige, types de
#      notification...) — directement issues du diagramme UML et du
#      cahier des charges, section "États du produit — cycle de vie".
#   2. lib/domain/entities/   → les 9 classes métier du diagramme de
#      classes (Utilisateur, Produit, Photo, Commande, Paiement,
#      DemandeVendeur, Mission, Litige, Notification), traduites en
#      classes Dart immuables (pattern copyWith), AVEC en plus deux
#      entités utilitaires nécessaires à l'UI mais absentes du diagramme
#      UML d'origine (Conversation/Message pour la messagerie, et
#      Categorie pour le catalogue) — précisées en commentaire.
#
# POURQUOI DES ENTITÉS "DOMAIN" SÉPARÉES DES "MODELS" DE DONNÉES ?
#   Ces classes dans lib/domain/entities sont des objets métier PURS :
#   elles ne savent rien de Hive, ni de JSON, ni d'aucune техно de
#   stockage. Ce sont elles que les écrans (UI) manipulent.
#   Le script 04 créera ensuite, dans lib/data/models, des classes
#   "Model" miroirs qui SAVENT se sérialiser (toJson/fromJson) et se
#   convertir en/depuis ces entités. Cette séparation est ce qui permet
#   de changer complètement de système de stockage (Hive → API) sans
#   jamais modifier le code des écrans : eux ne voient que le domaine.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 03_domain_models.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 03 terminé avec succès."
#   Aucune commande pub get nécessaire (pas de nouvelle dépendance).
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 03/14 : Enums et Entités du domaine"
echo "============================================================"

if [ ! -d "lib/domain" ]; then
  echo "ERREUR : lib/domain introuvable. Avez-vous exécuté le script 01 ?"
  exit 1
fi

# ============================================================================
# 1. RÔLES UTILISATEUR
# ============================================================================
cat > lib/domain/enums/user_role.dart << 'EOF'
/// Les 5 rôles distincts de la plateforme, conformes au cahier des
/// charges. Chaque rôle a son propre espace applicatif et ses propres
/// permissions : un Acheteur ne voit jamais les écrans Agent, etc.
enum UserRole {
  acheteur,
  vendeur,
  agentTerrain,
  admin,
  superAdmin;

  String get label {
    switch (this) {
      case UserRole.acheteur:
        return 'Acheteur';
      case UserRole.vendeur:
        return 'Vendeur';
      case UserRole.agentTerrain:
        return 'Agent terrain';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.superAdmin:
        return 'Super administrateur';
    }
  }

  /// Indique si ce rôle a accès au panneau web (Admin / Super Admin),
  /// par opposition aux rôles mobiles (Acheteur, Vendeur, Agent).
  bool get isWebRole => this == UserRole.admin || this == UserRole.superAdmin;
}
EOF
echo "→ lib/domain/enums/user_role.dart créé."

# ============================================================================
# 2. STATUT PRODUIT — cycle de vie complet (8 états + 4 exceptions)
# ============================================================================
cat > lib/domain/enums/product_status.dart << 'EOF'
import 'package:flutter/material.dart';

/// Cycle de vie complet d'un produit, conforme à la section "États du
/// produit" du cahier des charges. 8 états normaux séquentiels, plus
/// 4 états d'exception qui peuvent survenir à différents moments.
///
/// IMPORTANT : ces statuts sont la référence UNIQUE utilisée par tous
/// les rôles (Vendeur, Agent, Admin) pour savoir où en est un produit.
/// Zéro ambiguïté, comme exigé par le cahier des charges.
enum ProductStatus {
  // ── Cycle normal ──
  soumis,
  missionAssignee,
  enVerification,
  collecte,
  enTraitement,
  enVente,
  reserve,
  enLivraison,
  livre,

  // ── États d'exception ──
  refuse,
  annule,
  indisponible,
  expire;

  String get label {
    switch (this) {
      case ProductStatus.soumis:
        return 'Soumis';
      case ProductStatus.missionAssignee:
        return 'Mission assignée';
      case ProductStatus.enVerification:
        return 'En vérification';
      case ProductStatus.collecte:
        return 'Collecté';
      case ProductStatus.enTraitement:
        return 'En traitement';
      case ProductStatus.enVente:
        return 'En vente';
      case ProductStatus.reserve:
        return 'Réservé';
      case ProductStatus.enLivraison:
        return 'En livraison';
      case ProductStatus.livre:
        return 'Livré';
      case ProductStatus.refuse:
        return 'Refusé';
      case ProductStatus.annule:
        return 'Annulé';
      case ProductStatus.indisponible:
        return 'Indisponible';
      case ProductStatus.expire:
        return 'Expiré';
    }
  }

  /// Courte explication affichée à l'utilisateur, reprise du cahier
  /// des charges, pour qu'il comprenne exactement où en est son produit
  /// sans avoir besoin d'aide extérieure.
  String get description {
    switch (this) {
      case ProductStatus.soumis:
        return 'Demande reçue, en attente d\'assignation.';
      case ProductStatus.missionAssignee:
        return 'Un agent a été désigné pour la collecte.';
      case ProductStatus.enVerification:
        return 'L\'agent est chez le vendeur pour vérification.';
      case ProductStatus.collecte:
        return 'Le produit a été récupéré par l\'agent.';
      case ProductStatus.enTraitement:
        return 'Photos et fiche produit en préparation.';
      case ProductStatus.enVente:
        return 'Publié et visible sur la boutique.';
      case ProductStatus.reserve:
        return 'Paiement en attente de confirmation.';
      case ProductStatus.enLivraison:
        return 'En cours de remise à l\'acheteur.';
      case ProductStatus.livre:
        return 'Transaction terminée avec succès.';
      case ProductStatus.refuse:
        return 'Propriété non prouvée lors de la visite.';
      case ProductStatus.annule:
        return 'Le vendeur a annulé avant la collecte.';
      case ProductStatus.indisponible:
        return 'Produit endommagé ou perdu après collecte.';
      case ProductStatus.expire:
        return 'En vente depuis trop longtemps, retourné au vendeur.';
    }
  }

  bool get isException =>
      this == ProductStatus.refuse ||
      this == ProductStatus.annule ||
      this == ProductStatus.indisponible ||
      this == ProductStatus.expire;

  /// Indique si le produit peut être affiché et acheté dans la boutique.
  bool get isPurchasable => this == ProductStatus.enVente;

  Color get color {
    switch (this) {
      case ProductStatus.soumis:
        return const Color(0xFFF59E0B);
      case ProductStatus.missionAssignee:
        return const Color(0xFF2563EB);
      case ProductStatus.enVerification:
        return const Color(0xFF7C3AED);
      case ProductStatus.collecte:
      case ProductStatus.enTraitement:
        return const Color(0xFF0D9488);
      case ProductStatus.enVente:
        return const Color(0xFF059669);
      case ProductStatus.reserve:
        return const Color(0xFF5B21B6);
      case ProductStatus.enLivraison:
        return const Color(0xFF2563EB);
      case ProductStatus.livre:
        return const Color(0xFF166534);
      case ProductStatus.refuse:
      case ProductStatus.indisponible:
        return const Color(0xFFDC2626);
      case ProductStatus.annule:
        return const Color(0xFF6B7280);
      case ProductStatus.expire:
        return const Color(0xFF9CA3AF);
    }
  }

  /// Ordre d'avancement dans le cycle normal, utilisé pour dessiner une
  /// barre de progression. Les états d'exception renvoient -1 (ils
  /// sortent du flux normal et sont affichés différemment).
  int get progressIndex {
    const order = [
      ProductStatus.soumis,
      ProductStatus.missionAssignee,
      ProductStatus.enVerification,
      ProductStatus.collecte,
      ProductStatus.enTraitement,
      ProductStatus.enVente,
      ProductStatus.reserve,
      ProductStatus.enLivraison,
      ProductStatus.livre,
    ];
    final idx = order.indexOf(this);
    return idx;
  }
}

/// État physique du produit (différent du statut de cycle de vie).
/// Renseigné par l'agent terrain lors de la vérification.
enum ProductCondition {
  neuf,
  commeNeuf,
  bonEtat,
  etatCorrect,
  defautConnu;

  String get label {
    switch (this) {
      case ProductCondition.neuf:
        return 'Neuf';
      case ProductCondition.commeNeuf:
        return 'Comme neuf';
      case ProductCondition.bonEtat:
        return 'Bon état';
      case ProductCondition.etatCorrect:
        return 'État correct';
      case ProductCondition.defautConnu:
        return 'Défaut connu';
    }
  }
}
EOF
echo "→ lib/domain/enums/product_status.dart créé."

# ============================================================================
# 3. STATUT COMMANDE, PAIEMENT, MODE DE LIVRAISON
# ============================================================================
cat > lib/domain/enums/order_status.dart << 'EOF'
import 'package:flutter/material.dart';

/// Statuts de commande conformes au diagramme UML :
/// PENDANTE | PAYEE | EN_LIVRAISON | LIVREE | ANNULEE.
enum OrderStatus {
  pendante,
  payee,
  enLivraison,
  livree,
  annulee;

  String get label {
    switch (this) {
      case OrderStatus.pendante:
        return 'En attente de paiement';
      case OrderStatus.payee:
        return 'Payée';
      case OrderStatus.enLivraison:
        return 'En livraison';
      case OrderStatus.livree:
        return 'Livrée';
      case OrderStatus.annulee:
        return 'Annulée';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pendante:
        return const Color(0xFFF59E0B);
      case OrderStatus.payee:
        return const Color(0xFF2563EB);
      case OrderStatus.enLivraison:
        return const Color(0xFF7C3AED);
      case OrderStatus.livree:
        return const Color(0xFF059669);
      case OrderStatus.annulee:
        return const Color(0xFFDC2626);
    }
  }
}

enum DeliveryMode {
  livraison,
  retrait;

  String get label =>
      this == DeliveryMode.livraison ? 'Livraison à domicile' : 'Retrait en point relais';
}
EOF
echo "→ lib/domain/enums/order_status.dart créé."

cat > lib/domain/enums/payment_status.dart << 'EOF'
import 'package:flutter/material.dart';

/// Statuts de paiement conformes au diagramme UML :
/// EN_ATTENTE | VALIDE | ECHEC | REMBOURSE.
enum PaymentStatus {
  enAttente,
  valide,
  echec,
  rembourse;

  String get label {
    switch (this) {
      case PaymentStatus.enAttente:
        return 'En attente';
      case PaymentStatus.valide:
        return 'Validé';
      case PaymentStatus.echec:
        return 'Échoué';
      case PaymentStatus.rembourse:
        return 'Remboursé';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.enAttente:
        return const Color(0xFFF59E0B);
      case PaymentStatus.valide:
        return const Color(0xFF059669);
      case PaymentStatus.echec:
        return const Color(0xFFDC2626);
      case PaymentStatus.rembourse:
        return const Color(0xFF6B7280);
    }
  }
}

/// Méthodes de paiement disponibles, conformes au cahier des charges
/// (Mobile Money uniquement pour le marché camerounais).
enum PaymentMethod {
  orangeMoney,
  mtnMomo;

  String get label =>
      this == PaymentMethod.orangeMoney ? 'Orange Money' : 'MTN Mobile Money';
}
EOF
echo "→ lib/domain/enums/payment_status.dart créé."

# ============================================================================
# 4. STATUT DEMANDE VENDEUR
# ============================================================================
cat > lib/domain/enums/seller_request_status.dart << 'EOF'
import 'package:flutter/material.dart';

/// Statut d'une demande de soumission de produit par un vendeur,
/// avant qu'un agent ne soit assigné (voir Mission pour la suite
/// du processus terrain).
enum SellerRequestStatus {
  enAttente,
  validee,
  refusee,
  agentAssigne,
  terminee;

  String get label {
    switch (this) {
      case SellerRequestStatus.enAttente:
        return 'En attente d\'examen';
      case SellerRequestStatus.validee:
        return 'Validée';
      case SellerRequestStatus.refusee:
        return 'Refusée';
      case SellerRequestStatus.agentAssigne:
        return 'Agent assigné';
      case SellerRequestStatus.terminee:
        return 'Terminée';
    }
  }

  Color get color {
    switch (this) {
      case SellerRequestStatus.enAttente:
        return const Color(0xFFF59E0B);
      case SellerRequestStatus.validee:
        return const Color(0xFF2563EB);
      case SellerRequestStatus.refusee:
        return const Color(0xFFDC2626);
      case SellerRequestStatus.agentAssigne:
        return const Color(0xFF7C3AED);
      case SellerRequestStatus.terminee:
        return const Color(0xFF059669);
    }
  }
}
EOF
echo "→ lib/domain/enums/seller_request_status.dart créé."

# ============================================================================
# 5. STATUT ET TYPE DE MISSION (agent terrain)
# ============================================================================
cat > lib/domain/enums/mission_status.dart << 'EOF'
import 'package:flutter/material.dart';

/// Type de mission confiée à un agent terrain, conforme au diagramme
/// UML : COLLECTE ou LIVRAISON.
enum MissionType {
  collecte,
  livraison;

  String get label => this == MissionType.collecte ? 'Collecte' : 'Livraison';
}

/// Statut d'avancement d'une mission, conforme au diagramme UML :
/// COLLECTE | LIVRAISON | COMPLETE | ECHEC (réinterprété ici comme un
/// statut de progression distinct du type, pour éviter toute ambiguïté
/// entre "type de mission" et "où en est la mission").
enum MissionStatus {
  assignee,
  enRoute,
  surSite,
  complete,
  echec;

  String get label {
    switch (this) {
      case MissionStatus.assignee:
        return 'Assignée';
      case MissionStatus.enRoute:
        return 'En route';
      case MissionStatus.surSite:
        return 'Sur site';
      case MissionStatus.complete:
        return 'Complétée';
      case MissionStatus.echec:
        return 'Échec';
    }
  }

  Color get color {
    switch (this) {
      case MissionStatus.assignee:
        return const Color(0xFFF59E0B);
      case MissionStatus.enRoute:
        return const Color(0xFF2563EB);
      case MissionStatus.surSite:
        return const Color(0xFF7C3AED);
      case MissionStatus.complete:
        return const Color(0xFF059669);
      case MissionStatus.echec:
        return const Color(0xFFDC2626);
    }
  }
}
EOF
echo "→ lib/domain/enums/mission_status.dart créé."

# ============================================================================
# 6. STATUT LITIGE ET NOTIFICATION
# ============================================================================
cat > lib/domain/enums/dispute_status.dart << 'EOF'
import 'package:flutter/material.dart';

enum DisputeStatus {
  ouvert,
  enExamen,
  resolu,
  rejete;

  String get label {
    switch (this) {
      case DisputeStatus.ouvert:
        return 'Ouvert';
      case DisputeStatus.enExamen:
        return 'En examen';
      case DisputeStatus.resolu:
        return 'Résolu';
      case DisputeStatus.rejete:
        return 'Rejeté';
    }
  }

  Color get color {
    switch (this) {
      case DisputeStatus.ouvert:
        return const Color(0xFFDC2626);
      case DisputeStatus.enExamen:
        return const Color(0xFFF59E0B);
      case DisputeStatus.resolu:
        return const Color(0xFF059669);
      case DisputeStatus.rejete:
        return const Color(0xFF6B7280);
    }
  }
}
EOF
echo "→ lib/domain/enums/dispute_status.dart créé."

cat > lib/domain/enums/notification_type.dart << 'EOF'
/// Type de notification, déterminant l'icône et la destination au clic.
enum NotificationType {
  commande,
  produit,
  mission,
  paiement,
  litige,
  message,
  systeme;
}

/// Canal d'envoi de la notification, conforme au diagramme UML.
/// Pour l'instant seul [push] est réellement utilisé (notifications
/// locales), [sms] et [email] sont préparés pour une intégration future.
enum NotificationChannel { push, sms, email }
EOF
echo "→ lib/domain/enums/notification_type.dart créé."

cat > lib/domain/enums/photo_type.dart << 'EOF'
/// Type de photo associée à un produit.
///
/// [previewVendeur]  : photo facultative jointe par le vendeur lors de
///                     sa soumission, à titre indicatif uniquement.
/// [officielleAgent] : photo prise in-app par l'agent terrain lors de
///                     la vérification — c'est UNIQUEMENT celle-ci qui
///                     est utilisée pour la fiche produit publiée.
enum PhotoType { previewVendeur, officielleAgent }
EOF
echo "→ lib/domain/enums/photo_type.dart créé."

# ============================================================================
# 7. ENTITÉ : Utilisateur
# ============================================================================
cat > lib/domain/entities/utilisateur.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/user_role.dart';

/// Entité métier Utilisateur, conforme au diagramme UML.
///
/// Cette classe est volontairement immuable (tous les champs sont
/// `final`) : pour modifier un utilisateur, on crée une nouvelle
/// instance via [copyWith] plutôt que de muter l'objet existant. Cela
/// évite des bugs subtils où une partie de l'UI affiche encore
/// l'ancien état d'un objet modifié ailleurs.
class Utilisateur extends Equatable {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  // Le mot de passe n'est JAMAIS stocké en clair ici : ce champ
  // contient un hash simple en mode local, ou n'est simplement pas
  // utilisé une fois le token de session API obtenu en mode API.
  final String motDePasseHash;
  final UserRole role;
  final bool estActif;
  final String? photoUrl;
  final String? ville;
  final double? noteVendeur;
  final DateTime dateInscription;

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.motDePasseHash,
    required this.role,
    required this.dateInscription,
    this.estActif = true,
    this.photoUrl,
    this.ville,
    this.noteVendeur,
  });

  String get nomComplet => '$prenom $nom';

  /// Initiales utilisées comme avatar de repli quand aucune photo
  /// n'est disponible (ex: "JD" pour "Jean Dupont").
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  Utilisateur copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? telephone,
    String? motDePasseHash,
    UserRole? role,
    bool? estActif,
    String? photoUrl,
    String? ville,
    double? noteVendeur,
    DateTime? dateInscription,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      motDePasseHash: motDePasseHash ?? this.motDePasseHash,
      role: role ?? this.role,
      estActif: estActif ?? this.estActif,
      photoUrl: photoUrl ?? this.photoUrl,
      ville: ville ?? this.ville,
      noteVendeur: noteVendeur ?? this.noteVendeur,
      dateInscription: dateInscription ?? this.dateInscription,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nom,
        prenom,
        telephone,
        motDePasseHash,
        role,
        estActif,
        photoUrl,
        ville,
        noteVendeur,
        dateInscription,
      ];
}
EOF
echo "→ lib/domain/entities/utilisateur.dart créé."

# ============================================================================
# 8. ENTITÉ : Photo
# ============================================================================
cat > lib/domain/entities/photo.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/photo_type.dart';

/// Entité métier Photo, conforme au diagramme UML.
///
/// Le champ [url] contient, selon le contexte :
///   - en mode local sur mobile : un chemin de fichier local
///     (ex: /data/user/0/.../image123.jpg)
///   - en mode local sur web : une URL de données en mémoire (blob)
///   - en mode API : une URL HTTP réelle pointant vers le serveur
/// Cette ambiguïté volontaire est gérée par le widget d'affichage
/// d'image partagé (voir lib/shared/widgets), qui sait choisir la
/// bonne méthode de chargement selon la plateforme et le mode.
class Photo extends Equatable {
  final String id;
  final String url;
  final PhotoType type;
  final bool estOfficielle;
  final DateTime horodatage;
  final String? geoloc;

  const Photo({
    required this.id,
    required this.url,
    required this.type,
    required this.horodatage,
    this.estOfficielle = false,
    this.geoloc,
  });

  Photo copyWith({
    String? id,
    String? url,
    PhotoType? type,
    bool? estOfficielle,
    DateTime? horodatage,
    String? geoloc,
  }) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      estOfficielle: estOfficielle ?? this.estOfficielle,
      horodatage: horodatage ?? this.horodatage,
      geoloc: geoloc ?? this.geoloc,
    );
  }

  @override
  List<Object?> get props => [id, url, type, estOfficielle, horodatage, geoloc];
}
EOF
echo "→ lib/domain/entities/photo.dart créé."

# ============================================================================
# 9. ENTITÉ : Categorie (utilitaire, non présente dans le diagramme UML
#    d'origine mais nécessaire pour le catalogue — voir cahier des
#    charges, "Gestion des catégories et sous-catégories")
# ============================================================================
cat > lib/domain/entities/categorie.dart << 'EOF'
import 'package:equatable/equatable.dart';

/// Catégorie de produit (Électronique, Mode, Maison, Véhicules...).
///
/// Cette entité n'apparaît pas explicitement comme une classe à part
/// dans le diagramme UML fourni (où Produit.categorie est un simple
/// champ texte), mais le cahier des charges mentionne explicitement la
/// "Gestion des catégories et sous-catégories" côté Admin. On la
/// modélise donc en entité distincte pour permettre cette gestion
/// (ajout/édition de catégories) sans avoir à modifier du texte libre
/// dans chaque produit existant.
class Categorie extends Equatable {
  final String id;
  final String nom;
  final String? iconeAsset;
  final String? parentId;
  final int ordreAffichage;

  const Categorie({
    required this.id,
    required this.nom,
    this.iconeAsset,
    this.parentId,
    this.ordreAffichage = 0,
  });

  bool get estSousCategorie => parentId != null;

  Categorie copyWith({
    String? id,
    String? nom,
    String? iconeAsset,
    String? parentId,
    int? ordreAffichage,
  }) {
    return Categorie(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      iconeAsset: iconeAsset ?? this.iconeAsset,
      parentId: parentId ?? this.parentId,
      ordreAffichage: ordreAffichage ?? this.ordreAffichage,
    );
  }

  @override
  List<Object?> get props => [id, nom, iconeAsset, parentId, ordreAffichage];
}
EOF
echo "→ lib/domain/entities/categorie.dart créé."

# ============================================================================
# 10. ENTITÉ : Produit
# ============================================================================
cat > lib/domain/entities/produit.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/product_status.dart';
import 'photo.dart';

/// Entité métier Produit, conforme au diagramme UML, enrichie des
/// champs nécessaires au cycle de vie complet décrit dans le cahier
/// des charges (vendeur propriétaire, agent assigné, commission...).
class Produit extends Equatable {
  final String id;
  final String titre;
  final String description;
  final double prix;
  final ProductCondition etat;
  final ProductStatus statut;
  final String categorieId;
  final DateTime dateCreation;

  /// Identifiant du vendeur ayant soumis ce produit.
  final String vendeurId;

  /// Identifiant de l'agent assigné pour la collecte/vérification.
  /// Null tant qu'aucun agent n'a été assigné (statut "Soumis").
  final String? agentId;

  final List<Photo> photos;
  final String localisation;

  /// Défauts connus, affichés de façon transparente à l'acheteur,
  /// conformément à l'exigence du cahier des charges ("Affichage
  /// transparent des défauts connus" / mention "défaut inconnu").
  final String? defautsConnus;

  /// Taux de commission appliqué à ce produit (en pourcentage),
  /// déterminé par sa catégorie au moment de la mise en vente.
  final double tauxCommission;

  /// Raison du refus ou de l'indisponibilité, si applicable.
  final String? raisonException;

  const Produit({
    required this.id,
    required this.titre,
    required this.description,
    required this.prix,
    required this.etat,
    required this.statut,
    required this.categorieId,
    required this.dateCreation,
    required this.vendeurId,
    required this.localisation,
    required this.tauxCommission,
    this.agentId,
    this.photos = const [],
    this.defautsConnus,
    this.raisonException,
  });

  /// Montant net que le vendeur recevra une fois la commission
  /// déduite. Utilisé sur l'écran de suivi vendeur pour la
  /// transparence financière.
  double get montantNetVendeur => prix - (prix * tauxCommission / 100);

  /// Photo principale à afficher dans les listes (la première photo
  /// officielle si elle existe, sinon la première disponible).
  Photo? get photoPrincipale {
    if (photos.isEmpty) return null;
    final officielles = photos.where((p) => p.estOfficielle);
    return officielles.isNotEmpty ? officielles.first : photos.first;
  }

  Produit copyWith({
    String? id,
    String? titre,
    String? description,
    double? prix,
    ProductCondition? etat,
    ProductStatus? statut,
    String? categorieId,
    DateTime? dateCreation,
    String? vendeurId,
    String? agentId,
    List<Photo>? photos,
    String? localisation,
    double? tauxCommission,
    String? defautsConnus,
    String? raisonException,
  }) {
    return Produit(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      etat: etat ?? this.etat,
      statut: statut ?? this.statut,
      categorieId: categorieId ?? this.categorieId,
      dateCreation: dateCreation ?? this.dateCreation,
      vendeurId: vendeurId ?? this.vendeurId,
      agentId: agentId ?? this.agentId,
      photos: photos ?? this.photos,
      localisation: localisation ?? this.localisation,
      tauxCommission: tauxCommission ?? this.tauxCommission,
      defautsConnus: defautsConnus ?? this.defautsConnus,
      raisonException: raisonException ?? this.raisonException,
    );
  }

  @override
  List<Object?> get props => [
        id,
        titre,
        description,
        prix,
        etat,
        statut,
        categorieId,
        dateCreation,
        vendeurId,
        agentId,
        photos,
        localisation,
        tauxCommission,
        defautsConnus,
        raisonException,
      ];
}
EOF
echo "→ lib/domain/entities/produit.dart créé."

# ============================================================================
# 11. ENTITÉ : Commande
# ============================================================================
cat > lib/domain/entities/commande.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/order_status.dart';

/// Entité métier Commande, conforme au diagramme UML.
class Commande extends Equatable {
  final String id;
  final String reference;
  final double montantTotal;
  final OrderStatus statut;
  final DateTime dateCommande;
  final DeliveryMode modeLivraison;
  final String adresseLivraison;

  final String acheteurId;
  final String produitId;

  /// Identifiant de la mission de livraison associée, renseigné une
  /// fois qu'un agent a été assigné pour livrer la commande.
  final String? missionLivraisonId;

  const Commande({
    required this.id,
    required this.reference,
    required this.montantTotal,
    required this.statut,
    required this.dateCommande,
    required this.modeLivraison,
    required this.adresseLivraison,
    required this.acheteurId,
    required this.produitId,
    this.missionLivraisonId,
  });

  Commande copyWith({
    String? id,
    String? reference,
    double? montantTotal,
    OrderStatus? statut,
    DateTime? dateCommande,
    DeliveryMode? modeLivraison,
    String? adresseLivraison,
    String? acheteurId,
    String? produitId,
    String? missionLivraisonId,
  }) {
    return Commande(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      montantTotal: montantTotal ?? this.montantTotal,
      statut: statut ?? this.statut,
      dateCommande: dateCommande ?? this.dateCommande,
      modeLivraison: modeLivraison ?? this.modeLivraison,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      acheteurId: acheteurId ?? this.acheteurId,
      produitId: produitId ?? this.produitId,
      missionLivraisonId: missionLivraisonId ?? this.missionLivraisonId,
    );
  }

  /// Génère une référence de commande lisible, conforme au format
  /// observé dans le scénario d'achat (#CM-2024-XXXX).
  static String genererReference(int sequence, {int? annee}) {
    final year = annee ?? DateTime.now().year;
    return 'CM-$year-${sequence.toString().padLeft(4, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        reference,
        montantTotal,
        statut,
        dateCommande,
        modeLivraison,
        adresseLivraison,
        acheteurId,
        produitId,
        missionLivraisonId,
      ];
}
EOF
echo "→ lib/domain/entities/commande.dart créé."

# ============================================================================
# 12. ENTITÉ : Paiement
# ============================================================================
cat > lib/domain/entities/paiement.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/payment_status.dart';

/// Entité métier Paiement, conforme au diagramme UML.
class Paiement extends Equatable {
  final String id;
  final double montant;
  final PaymentMethod methode;
  final String reference;
  final PaymentStatus statut;
  final DateTime dateHeure;
  final String numeroPaieur;
  final String commandeId;

  const Paiement({
    required this.id,
    required this.montant,
    required this.methode,
    required this.reference,
    required this.statut,
    required this.dateHeure,
    required this.numeroPaieur,
    required this.commandeId,
  });

  Paiement copyWith({
    String? id,
    double? montant,
    PaymentMethod? methode,
    String? reference,
    PaymentStatus? statut,
    DateTime? dateHeure,
    String? numeroPaieur,
    String? commandeId,
  }) {
    return Paiement(
      id: id ?? this.id,
      montant: montant ?? this.montant,
      methode: methode ?? this.methode,
      reference: reference ?? this.reference,
      statut: statut ?? this.statut,
      dateHeure: dateHeure ?? this.dateHeure,
      numeroPaieur: numeroPaieur ?? this.numeroPaieur,
      commandeId: commandeId ?? this.commandeId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        montant,
        methode,
        reference,
        statut,
        dateHeure,
        numeroPaieur,
        commandeId,
      ];
}
EOF
echo "→ lib/domain/entities/paiement.dart créé."

# ============================================================================
# 13. ENTITÉ : DemandeVendeur
# ============================================================================
cat > lib/domain/entities/demande_vendeur.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/seller_request_status.dart';

/// Entité métier DemandeVendeur, conforme au diagramme UML.
///
/// Représente la soumission initiale d'un vendeur, AVANT que le
/// produit ne soit formellement créé en base (le Produit n'existe
/// véritablement, avec ses photos officielles, qu'après la collecte
/// par l'agent — voir entité Produit).
class DemandeVendeur extends Equatable {
  final String id;
  final SellerRequestStatus statut;
  final String adresse;
  final String disponibilite;
  final String contactVendeur;
  final String zone;
  final DateTime dateCreation;

  final String vendeurId;
  final String typeProduitSouhaite;
  final int quantite;
  final String descriptionInitiale;
  final double prixSouhaite;

  /// Identifiant de la mission créée une fois un agent assigné.
  final String? missionId;

  /// Raison du refus, si applicable.
  final String? raisonRefus;

  const DemandeVendeur({
    required this.id,
    required this.statut,
    required this.adresse,
    required this.disponibilite,
    required this.contactVendeur,
    required this.zone,
    required this.dateCreation,
    required this.vendeurId,
    required this.typeProduitSouhaite,
    required this.quantite,
    required this.descriptionInitiale,
    required this.prixSouhaite,
    this.missionId,
    this.raisonRefus,
  });

  DemandeVendeur copyWith({
    String? id,
    SellerRequestStatus? statut,
    String? adresse,
    String? disponibilite,
    String? contactVendeur,
    String? zone,
    DateTime? dateCreation,
    String? vendeurId,
    String? typeProduitSouhaite,
    int? quantite,
    String? descriptionInitiale,
    double? prixSouhaite,
    String? missionId,
    String? raisonRefus,
  }) {
    return DemandeVendeur(
      id: id ?? this.id,
      statut: statut ?? this.statut,
      adresse: adresse ?? this.adresse,
      disponibilite: disponibilite ?? this.disponibilite,
      contactVendeur: contactVendeur ?? this.contactVendeur,
      zone: zone ?? this.zone,
      dateCreation: dateCreation ?? this.dateCreation,
      vendeurId: vendeurId ?? this.vendeurId,
      typeProduitSouhaite: typeProduitSouhaite ?? this.typeProduitSouhaite,
      quantite: quantite ?? this.quantite,
      descriptionInitiale: descriptionInitiale ?? this.descriptionInitiale,
      prixSouhaite: prixSouhaite ?? this.prixSouhaite,
      missionId: missionId ?? this.missionId,
      raisonRefus: raisonRefus ?? this.raisonRefus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        statut,
        adresse,
        disponibilite,
        contactVendeur,
        zone,
        dateCreation,
        vendeurId,
        typeProduitSouhaite,
        quantite,
        descriptionInitiale,
        prixSouhaite,
        missionId,
        raisonRefus,
      ];
}
EOF
echo "→ lib/domain/entities/demande_vendeur.dart créé."

# ============================================================================
# 14. ENTITÉ : Mission
# ============================================================================
cat > lib/domain/entities/mission.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/mission_status.dart';

/// Entité métier Mission, conforme au diagramme UML.
///
/// Une mission de type [MissionType.collecte] est liée à une
/// [DemandeVendeur] ; une mission de type [MissionType.livraison] est
/// liée à une [Commande]. Le champ [referenceId] pointe vers l'une ou
/// l'autre selon [type].
class Mission extends Equatable {
  final String id;
  final MissionType type;
  final MissionStatus statut;
  final DateTime dateHeure;
  final String? codeConfirmation;
  final int photosCount;

  final String agentId;
  final String referenceId;

  /// Notes prises par l'agent sur le terrain (état réel constaté,
  /// défauts observés...).
  final String? notesAgent;

  /// Raison du refus de la mission, si applicable.
  final String? raisonRefus;

  /// Coordonnées GPS de la mission, utilisées pour la navigation et
  /// l'horodatage géolocalisé des photos.
  final double? latitude;
  final double? longitude;

  const Mission({
    required this.id,
    required this.type,
    required this.statut,
    required this.dateHeure,
    required this.agentId,
    required this.referenceId,
    this.codeConfirmation,
    this.photosCount = 0,
    this.notesAgent,
    this.raisonRefus,
    this.latitude,
    this.longitude,
  });

  Mission copyWith({
    String? id,
    MissionType? type,
    MissionStatus? statut,
    DateTime? dateHeure,
    String? codeConfirmation,
    int? photosCount,
    String? agentId,
    String? referenceId,
    String? notesAgent,
    String? raisonRefus,
    double? latitude,
    double? longitude,
  }) {
    return Mission(
      id: id ?? this.id,
      type: type ?? this.type,
      statut: statut ?? this.statut,
      dateHeure: dateHeure ?? this.dateHeure,
      agentId: agentId ?? this.agentId,
      referenceId: referenceId ?? this.referenceId,
      codeConfirmation: codeConfirmation ?? this.codeConfirmation,
      photosCount: photosCount ?? this.photosCount,
      notesAgent: notesAgent ?? this.notesAgent,
      raisonRefus: raisonRefus ?? this.raisonRefus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        statut,
        dateHeure,
        codeConfirmation,
        photosCount,
        agentId,
        referenceId,
        notesAgent,
        raisonRefus,
        latitude,
        longitude,
      ];
}
EOF
echo "→ lib/domain/entities/mission.dart créé."

# ============================================================================
# 15. ENTITÉ : Litige
# ============================================================================
cat > lib/domain/entities/litige.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/dispute_status.dart';

/// Entité métier Litige, conforme au diagramme UML.
class Litige extends Equatable {
  final String id;
  final String motif;
  final DisputeStatus statut;
  final String? decision;
  final double? montantRembourse;
  final DateTime dateOuverture;

  final String commandeId;
  final String ouvertParUserId;

  /// Identifiant de l'admin ayant traité le litige, renseigné une fois
  /// la décision prise.
  final String? traiteParAdminId;

  const Litige({
    required this.id,
    required this.motif,
    required this.statut,
    required this.dateOuverture,
    required this.commandeId,
    required this.ouvertParUserId,
    this.decision,
    this.montantRembourse,
    this.traiteParAdminId,
  });

  Litige copyWith({
    String? id,
    String? motif,
    DisputeStatus? statut,
    String? decision,
    double? montantRembourse,
    DateTime? dateOuverture,
    String? commandeId,
    String? ouvertParUserId,
    String? traiteParAdminId,
  }) {
    return Litige(
      id: id ?? this.id,
      motif: motif ?? this.motif,
      statut: statut ?? this.statut,
      decision: decision ?? this.decision,
      montantRembourse: montantRembourse ?? this.montantRembourse,
      dateOuverture: dateOuverture ?? this.dateOuverture,
      commandeId: commandeId ?? this.commandeId,
      ouvertParUserId: ouvertParUserId ?? this.ouvertParUserId,
      traiteParAdminId: traiteParAdminId ?? this.traiteParAdminId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        motif,
        statut,
        decision,
        montantRembourse,
        dateOuverture,
        commandeId,
        ouvertParUserId,
        traiteParAdminId,
      ];
}
EOF
echo "→ lib/domain/entities/litige.dart créé."

# ============================================================================
# 16. ENTITÉ : Notification
# ============================================================================
cat > lib/domain/entities/notification_entity.dart << 'EOF'
import 'package:equatable/equatable.dart';
import '../enums/notification_type.dart';

/// Entité métier Notification, conforme au diagramme UML.
///
/// Nommée [NotificationEntity] (et non simplement Notification) pour
/// éviter tout conflit de nom avec les classes du SDK Flutter/système
/// qui utilisent parfois aussi ce mot.
class NotificationEntity extends Equatable {
  final String id;
  final String message;
  final NotificationType type;
  final bool estLue;
  final DateTime dateEnvoi;
  final NotificationChannel canal;

  final String destinataireId;

  /// Identifiant de l'entité concernée (commande, produit, mission...),
  /// utilisé pour naviguer directement vers l'écran pertinent au clic.
  final String? referenceId;

  const NotificationEntity({
    required this.id,
    required this.message,
    required this.type,
    required this.dateEnvoi,
    required this.destinataireId,
    this.estLue = false,
    this.canal = NotificationChannel.push,
    this.referenceId,
  });

  NotificationEntity copyWith({
    String? id,
    String? message,
    NotificationType? type,
    bool? estLue,
    DateTime? dateEnvoi,
    NotificationChannel? canal,
    String? destinataireId,
    String? referenceId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      estLue: estLue ?? this.estLue,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      canal: canal ?? this.canal,
      destinataireId: destinataireId ?? this.destinataireId,
      referenceId: referenceId ?? this.referenceId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        message,
        type,
        estLue,
        dateEnvoi,
        canal,
        destinataireId,
        referenceId,
      ];
}
EOF
echo "→ lib/domain/entities/notification_entity.dart créé."

# ============================================================================
# 17. ENTITÉS : Conversation et Message (messagerie interne)
#     Absentes du diagramme UML d'origine, mais nécessaires car la
#     messagerie figure explicitement dans les scénarios UX fournis
#     (écran "Messages" pour Acheteur, Vendeur, et messages avec le
#     Support AfriDeal).
# ============================================================================
cat > lib/domain/entities/conversation.dart << 'EOF'
import 'package:equatable/equatable.dart';

/// Conversation entre deux utilisateurs (ou un utilisateur et le
/// support AfriDeal). Entité ajoutée pour couvrir l'écran "Messages"
/// présent dans les scénarios UX, absent du diagramme de classes
/// d'origine qui se concentrait sur le processus d'achat/vente.
class Conversation extends Equatable {
  final String id;
  final List<String> participantIds;
  final String? produitId;
  final String dernierMessage;
  final DateTime dateDernierMessage;
  final int nombreNonLus;
  final bool estSupport;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.dernierMessage,
    required this.dateDernierMessage,
    this.produitId,
    this.nombreNonLus = 0,
    this.estSupport = false,
  });

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    String? produitId,
    String? dernierMessage,
    DateTime? dateDernierMessage,
    int? nombreNonLus,
    bool? estSupport,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      produitId: produitId ?? this.produitId,
      dernierMessage: dernierMessage ?? this.dernierMessage,
      dateDernierMessage: dateDernierMessage ?? this.dateDernierMessage,
      nombreNonLus: nombreNonLus ?? this.nombreNonLus,
      estSupport: estSupport ?? this.estSupport,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        produitId,
        dernierMessage,
        dateDernierMessage,
        nombreNonLus,
        estSupport,
      ];
}
EOF
echo "→ lib/domain/entities/conversation.dart créé."

cat > lib/domain/entities/message.dart << 'EOF'
import 'package:equatable/equatable.dart';

/// Message individuel au sein d'une [Conversation].
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String contenu;
  final DateTime dateEnvoi;
  final bool estLu;

  const Message({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.contenu,
    required this.dateEnvoi,
    this.estLu = false,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? expediteurId,
    String? contenu,
    DateTime? dateEnvoi,
    bool? estLu,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      expediteurId: expediteurId ?? this.expediteurId,
      contenu: contenu ?? this.contenu,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      estLu: estLu ?? this.estLu,
    );
  }

  @override
  List<Object?> get props =>
      [id, conversationId, expediteurId, contenu, dateEnvoi, estLu];
}
EOF
echo "→ lib/domain/entities/message.dart créé."

echo ""
echo "============================================================"
echo "  ✔ Script 03 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • 9 fichiers d'énumérations (rôles, statuts produit avec les"
echo "    12 états du cycle de vie, commande, paiement, mission,"
echo "    demande vendeur, litige, notification, type de photo)"
echo "  • 11 entités métier immuables : Utilisateur, Photo, Categorie,"
echo "    Produit, Commande, Paiement, DemandeVendeur, Mission,"
echo "    Litige, Notification, + Conversation/Message pour la"
echo "    messagerie interne"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 04 : la couche"
echo "  de données locale (Hive) — adapters, repositories locaux,"
echo "  et les données de démonstration (comptes test, produits"
echo "  d'exemple) qui permettront de lancer l'app immédiatement."
echo ""

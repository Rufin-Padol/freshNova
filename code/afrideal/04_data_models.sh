#!/bin/bash
# ============================================================================
# SCRIPT 04 — Modèles de données JSON (lib/data/models)
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   Crée, pour chaque entité du domaine (script 03), un "Model" miroir
#   dans lib/data/models qui sait :
#     - se convertir en Map JSON (toJson) et se reconstruire depuis
#       un Map JSON (fromJson)
#     - se convertir vers l'entité métier pure (toEntity)
#     - se construire depuis une entité métier pure (fromEntity)
#
# POURQUOI CETTE SÉPARATION Model <-> Entity ?
#   L'entité (lib/domain/entities) ne sait RIEN de la sérialisation.
#   Le Model (lib/data/models) sait UNIQUEMENT se sérialiser. Ainsi :
#     - Les écrans manipulent des Entités, jamais des Models.
#     - Le stockage (Hive aujourd'hui, API demain) manipule des Models.
#   Changer complètement de mécanisme de stockage ne touche QUE les
#   Models et les Repositories (script 05), jamais les écrans.
#
# POURQUOI DU JSON DANS DES Box<String> PLUTÔT QUE DES TypeAdapter
# HIVE GÉNÉRÉS PAR build_runner ?
#   1. Zéro dépendance à la génération de code = zéro risque de
#      plantage de compilation lié à un fichier .g.dart manquant ou
#      désynchronisé (cause très fréquente de projets Flutter qui ne
#      démarrent plus après modification d'un modèle).
#   2. Stocker un Map brut dans une Box Hive typée renvoie parfois un
#      Map<dynamic, dynamic> au lieu de Map<String, dynamic> selon la
#      plateforme (problème connu et documenté de Hive), ce qui peut
#      provoquer un crash au cast. En passant systématiquement par
#      jsonEncode/jsonDecode (chaînes de caractères), ce problème
#      n'existe plus jamais : une String est une String sur toutes les
#      plateformes (Android, iOS, Web), sans exception.
#   3. Le code de sérialisation (toJson/fromJson) est explicite, lisible
#      et facilement déboggable — contrairement à un fichier généré.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 04_data_models.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 04 terminé avec succès."
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 04/14 : Modèles de données JSON"
echo "============================================================"

if [ ! -d "lib/domain/entities" ]; then
  echo "ERREUR : lib/domain/entities introuvable. Avez-vous exécuté le script 03 ?"
  exit 1
fi

mkdir -p lib/data/models

# ============================================================================
# 1. MODEL : UtilisateurModel
# ============================================================================
cat > lib/data/models/utilisateur_model.dart << 'EOF'
import '../../domain/entities/utilisateur.dart';
import '../../domain/enums/user_role.dart';

/// Représentation sérialisable de [Utilisateur], pour le stockage
/// local (Hive, en JSON) ou la future API (Dio, en JSON).
class UtilisateurModel {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String motDePasseHash;
  final String role;
  final bool estActif;
  final String? photoUrl;
  final String? ville;
  final double? noteVendeur;
  final String dateInscription;

  const UtilisateurModel({
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

  factory UtilisateurModel.fromEntity(Utilisateur e) {
    return UtilisateurModel(
      id: e.id,
      nom: e.nom,
      prenom: e.prenom,
      telephone: e.telephone,
      motDePasseHash: e.motDePasseHash,
      role: e.role.name,
      estActif: e.estActif,
      photoUrl: e.photoUrl,
      ville: e.ville,
      noteVendeur: e.noteVendeur,
      dateInscription: e.dateInscription.toIso8601String(),
    );
  }

  Utilisateur toEntity() {
    return Utilisateur(
      id: id,
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      motDePasseHash: motDePasseHash,
      role: UserRole.values.firstWhere((r) => r.name == role),
      estActif: estActif,
      photoUrl: photoUrl,
      ville: ville,
      noteVendeur: noteVendeur,
      dateInscription: DateTime.parse(dateInscription),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'motDePasseHash': motDePasseHash,
        'role': role,
        'estActif': estActif,
        'photoUrl': photoUrl,
        'ville': ville,
        'noteVendeur': noteVendeur,
        'dateInscription': dateInscription,
      };

  factory UtilisateurModel.fromJson(Map<String, dynamic> json) {
    return UtilisateurModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      telephone: json['telephone'] as String,
      motDePasseHash: json['motDePasseHash'] as String,
      role: json['role'] as String,
      estActif: json['estActif'] as bool? ?? true,
      photoUrl: json['photoUrl'] as String?,
      ville: json['ville'] as String?,
      noteVendeur: (json['noteVendeur'] as num?)?.toDouble(),
      dateInscription: json['dateInscription'] as String,
    );
  }
}
EOF
echo "→ lib/data/models/utilisateur_model.dart créé."

# ============================================================================
# 2. MODEL : PhotoModel
# ============================================================================
cat > lib/data/models/photo_model.dart << 'EOF'
import '../../domain/entities/photo.dart';
import '../../domain/enums/photo_type.dart';

class PhotoModel {
  final String id;
  final String url;
  final String type;
  final bool estOfficielle;
  final String horodatage;
  final String? geoloc;

  const PhotoModel({
    required this.id,
    required this.url,
    required this.type,
    required this.horodatage,
    this.estOfficielle = false,
    this.geoloc,
  });

  factory PhotoModel.fromEntity(Photo e) {
    return PhotoModel(
      id: e.id,
      url: e.url,
      type: e.type.name,
      estOfficielle: e.estOfficielle,
      horodatage: e.horodatage.toIso8601String(),
      geoloc: e.geoloc,
    );
  }

  Photo toEntity() {
    return Photo(
      id: id,
      url: url,
      type: PhotoType.values.firstWhere((t) => t.name == type),
      estOfficielle: estOfficielle,
      horodatage: DateTime.parse(horodatage),
      geoloc: geoloc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'type': type,
        'estOfficielle': estOfficielle,
        'horodatage': horodatage,
        'geoloc': geoloc,
      };

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      estOfficielle: json['estOfficielle'] as bool? ?? false,
      horodatage: json['horodatage'] as String,
      geoloc: json['geoloc'] as String?,
    );
  }
}
EOF
echo "→ lib/data/models/photo_model.dart créé."

# ============================================================================
# 3. MODEL : CategorieModel
# ============================================================================
cat > lib/data/models/categorie_model.dart << 'EOF'
import '../../domain/entities/categorie.dart';

class CategorieModel {
  final String id;
  final String nom;
  final String? iconeAsset;
  final String? parentId;
  final int ordreAffichage;

  const CategorieModel({
    required this.id,
    required this.nom,
    this.iconeAsset,
    this.parentId,
    this.ordreAffichage = 0,
  });

  factory CategorieModel.fromEntity(Categorie e) {
    return CategorieModel(
      id: e.id,
      nom: e.nom,
      iconeAsset: e.iconeAsset,
      parentId: e.parentId,
      ordreAffichage: e.ordreAffichage,
    );
  }

  Categorie toEntity() {
    return Categorie(
      id: id,
      nom: nom,
      iconeAsset: iconeAsset,
      parentId: parentId,
      ordreAffichage: ordreAffichage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'iconeAsset': iconeAsset,
        'parentId': parentId,
        'ordreAffichage': ordreAffichage,
      };

  factory CategorieModel.fromJson(Map<String, dynamic> json) {
    return CategorieModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      iconeAsset: json['iconeAsset'] as String?,
      parentId: json['parentId'] as String?,
      ordreAffichage: json['ordreAffichage'] as int? ?? 0,
    );
  }
}
EOF
echo "→ lib/data/models/categorie_model.dart créé."

# ============================================================================
# 4. MODEL : ProduitModel
# ============================================================================
cat > lib/data/models/produit_model.dart << 'EOF'
import '../../domain/entities/produit.dart';
import '../../domain/entities/photo.dart';
import '../../domain/enums/product_status.dart';
import 'photo_model.dart';

class ProduitModel {
  final String id;
  final String titre;
  final String description;
  final double prix;
  final String etat;
  final String statut;
  final String categorieId;
  final String dateCreation;
  final String vendeurId;
  final String? agentId;
  final List<PhotoModel> photos;
  final String localisation;
  final String? defautsConnus;
  final double tauxCommission;
  final String? raisonException;

  const ProduitModel({
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

  factory ProduitModel.fromEntity(Produit e) {
    return ProduitModel(
      id: e.id,
      titre: e.titre,
      description: e.description,
      prix: e.prix,
      etat: e.etat.name,
      statut: e.statut.name,
      categorieId: e.categorieId,
      dateCreation: e.dateCreation.toIso8601String(),
      vendeurId: e.vendeurId,
      agentId: e.agentId,
      photos: e.photos.map(PhotoModel.fromEntity).toList(),
      localisation: e.localisation,
      tauxCommission: e.tauxCommission,
      defautsConnus: e.defautsConnus,
      raisonException: e.raisonException,
    );
  }

  Produit toEntity() {
    return Produit(
      id: id,
      titre: titre,
      description: description,
      prix: prix,
      etat: ProductCondition.values.firstWhere((c) => c.name == etat),
      statut: ProductStatus.values.firstWhere((s) => s.name == statut),
      categorieId: categorieId,
      dateCreation: DateTime.parse(dateCreation),
      vendeurId: vendeurId,
      agentId: agentId,
      photos: photos.map((p) => p.toEntity()).toList(),
      localisation: localisation,
      tauxCommission: tauxCommission,
      defautsConnus: defautsConnus,
      raisonException: raisonException,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'description': description,
        'prix': prix,
        'etat': etat,
        'statut': statut,
        'categorieId': categorieId,
        'dateCreation': dateCreation,
        'vendeurId': vendeurId,
        'agentId': agentId,
        'photos': photos.map((p) => p.toJson()).toList(),
        'localisation': localisation,
        'defautsConnus': defautsConnus,
        'tauxCommission': tauxCommission,
        'raisonException': raisonException,
      };

  factory ProduitModel.fromJson(Map<String, dynamic> json) {
    return ProduitModel(
      id: json['id'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String,
      prix: (json['prix'] as num).toDouble(),
      etat: json['etat'] as String,
      statut: json['statut'] as String,
      categorieId: json['categorieId'] as String,
      dateCreation: json['dateCreation'] as String,
      vendeurId: json['vendeurId'] as String,
      agentId: json['agentId'] as String?,
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((p) => PhotoModel.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      localisation: json['localisation'] as String,
      defautsConnus: json['defautsConnus'] as String?,
      tauxCommission: (json['tauxCommission'] as num).toDouble(),
      raisonException: json['raisonException'] as String?,
    );
  }
}
EOF
echo "→ lib/data/models/produit_model.dart créé."

# ============================================================================
# 5. MODEL : CommandeModel
# ============================================================================
cat > lib/data/models/commande_model.dart << 'EOF'
import '../../domain/entities/commande.dart';
import '../../domain/enums/order_status.dart';

class CommandeModel {
  final String id;
  final String reference;
  final double montantTotal;
  final String statut;
  final String dateCommande;
  final String modeLivraison;
  final String adresseLivraison;
  final String acheteurId;
  final String produitId;
  final String? missionLivraisonId;

  const CommandeModel({
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

  factory CommandeModel.fromEntity(Commande e) {
    return CommandeModel(
      id: e.id,
      reference: e.reference,
      montantTotal: e.montantTotal,
      statut: e.statut.name,
      dateCommande: e.dateCommande.toIso8601String(),
      modeLivraison: e.modeLivraison.name,
      adresseLivraison: e.adresseLivraison,
      acheteurId: e.acheteurId,
      produitId: e.produitId,
      missionLivraisonId: e.missionLivraisonId,
    );
  }

  Commande toEntity() {
    return Commande(
      id: id,
      reference: reference,
      montantTotal: montantTotal,
      statut: OrderStatus.values.firstWhere((s) => s.name == statut),
      dateCommande: DateTime.parse(dateCommande),
      modeLivraison: DeliveryMode.values.firstWhere((m) => m.name == modeLivraison),
      adresseLivraison: adresseLivraison,
      acheteurId: acheteurId,
      produitId: produitId,
      missionLivraisonId: missionLivraisonId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'montantTotal': montantTotal,
        'statut': statut,
        'dateCommande': dateCommande,
        'modeLivraison': modeLivraison,
        'adresseLivraison': adresseLivraison,
        'acheteurId': acheteurId,
        'produitId': produitId,
        'missionLivraisonId': missionLivraisonId,
      };

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    return CommandeModel(
      id: json['id'] as String,
      reference: json['reference'] as String,
      montantTotal: (json['montantTotal'] as num).toDouble(),
      statut: json['statut'] as String,
      dateCommande: json['dateCommande'] as String,
      modeLivraison: json['modeLivraison'] as String,
      adresseLivraison: json['adresseLivraison'] as String,
      acheteurId: json['acheteurId'] as String,
      produitId: json['produitId'] as String,
      missionLivraisonId: json['missionLivraisonId'] as String?,
    );
  }
}
EOF
echo "→ lib/data/models/commande_model.dart créé."

# ============================================================================
# 6. MODEL : PaiementModel
# ============================================================================
cat > lib/data/models/paiement_model.dart << 'EOF'
import '../../domain/entities/paiement.dart';
import '../../domain/enums/payment_status.dart';

class PaiementModel {
  final String id;
  final double montant;
  final String methode;
  final String reference;
  final String statut;
  final String dateHeure;
  final String numeroPaieur;
  final String commandeId;

  const PaiementModel({
    required this.id,
    required this.montant,
    required this.methode,
    required this.reference,
    required this.statut,
    required this.dateHeure,
    required this.numeroPaieur,
    required this.commandeId,
  });

  factory PaiementModel.fromEntity(Paiement e) {
    return PaiementModel(
      id: e.id,
      montant: e.montant,
      methode: e.methode.name,
      reference: e.reference,
      statut: e.statut.name,
      dateHeure: e.dateHeure.toIso8601String(),
      numeroPaieur: e.numeroPaieur,
      commandeId: e.commandeId,
    );
  }

  Paiement toEntity() {
    return Paiement(
      id: id,
      montant: montant,
      methode: PaymentMethod.values.firstWhere((m) => m.name == methode),
      reference: reference,
      statut: PaymentStatus.values.firstWhere((s) => s.name == statut),
      dateHeure: DateTime.parse(dateHeure),
      numeroPaieur: numeroPaieur,
      commandeId: commandeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'montant': montant,
        'methode': methode,
        'reference': reference,
        'statut': statut,
        'dateHeure': dateHeure,
        'numeroPaieur': numeroPaieur,
        'commandeId': commandeId,
      };

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    return PaiementModel(
      id: json['id'] as String,
      montant: (json['montant'] as num).toDouble(),
      methode: json['methode'] as String,
      reference: json['reference'] as String,
      statut: json['statut'] as String,
      dateHeure: json['dateHeure'] as String,
      numeroPaieur: json['numeroPaieur'] as String,
      commandeId: json['commandeId'] as String,
    );
  }
}
EOF
echo "→ lib/data/models/paiement_model.dart créé."

# ============================================================================
# 7. MODEL : DemandeVendeurModel
# ============================================================================
cat > lib/data/models/demande_vendeur_model.dart << 'EOF'
import '../../domain/entities/demande_vendeur.dart';
import '../../domain/enums/seller_request_status.dart';

class DemandeVendeurModel {
  final String id;
  final String statut;
  final String adresse;
  final String disponibilite;
  final String contactVendeur;
  final String zone;
  final String dateCreation;
  final String vendeurId;
  final String typeProduitSouhaite;
  final int quantite;
  final String descriptionInitiale;
  final double prixSouhaite;
  final String? missionId;
  final String? raisonRefus;

  const DemandeVendeurModel({
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

  factory DemandeVendeurModel.fromEntity(DemandeVendeur e) {
    return DemandeVendeurModel(
      id: e.id,
      statut: e.statut.name,
      adresse: e.adresse,
      disponibilite: e.disponibilite,
      contactVendeur: e.contactVendeur,
      zone: e.zone,
      dateCreation: e.dateCreation.toIso8601String(),
      vendeurId: e.vendeurId,
      typeProduitSouhaite: e.typeProduitSouhaite,
      quantite: e.quantite,
      descriptionInitiale: e.descriptionInitiale,
      prixSouhaite: e.prixSouhaite,
      missionId: e.missionId,
      raisonRefus: e.raisonRefus,
    );
  }

  DemandeVendeur toEntity() {
    return DemandeVendeur(
      id: id,
      statut: SellerRequestStatus.values.firstWhere((s) => s.name == statut),
      adresse: adresse,
      disponibilite: disponibilite,
      contactVendeur: contactVendeur,
      zone: zone,
      dateCreation: DateTime.parse(dateCreation),
      vendeurId: vendeurId,
      typeProduitSouhaite: typeProduitSouhaite,
      quantite: quantite,
      descriptionInitiale: descriptionInitiale,
      prixSouhaite: prixSouhaite,
      missionId: missionId,
      raisonRefus: raisonRefus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'statut': statut,
        'adresse': adresse,
        'disponibilite': disponibilite,
        'contactVendeur': contactVendeur,
        'zone': zone,
        'dateCreation': dateCreation,
        'vendeurId': vendeurId,
        'typeProduitSouhaite': typeProduitSouhaite,
        'quantite': quantite,
        'descriptionInitiale': descriptionInitiale,
        'prixSouhaite': prixSouhaite,
        'missionId': missionId,
        'raisonRefus': raisonRefus,
      };

  factory DemandeVendeurModel.fromJson(Map<String, dynamic> json) {
    return DemandeVendeurModel(
      id: json['id'] as String,
      statut: json['statut'] as String,
      adresse: json['adresse'] as String,
      disponibilite: json['disponibilite'] as String,
      contactVendeur: json['contactVendeur'] as String,
      zone: json['zone'] as String,
      dateCreation: json['dateCreation'] as String,
      vendeurId: json['vendeurId'] as String,
      typeProduitSouhaite: json['typeProduitSouhaite'] as String,
      quantite: json['quantite'] as int,
      descriptionInitiale: json['descriptionInitiale'] as String,
      prixSouhaite: (json['prixSouhaite'] as num).toDouble(),
      missionId: json['missionId'] as String?,
      raisonRefus: json['raisonRefus'] as String?,
    );
  }
}
EOF
echo "→ lib/data/models/demande_vendeur_model.dart créé."

# ============================================================================
# 8. MODEL : MissionModel
# ============================================================================
cat > lib/data/models/mission_model.dart << 'EOF'
import '../../domain/entities/mission.dart';
import '../../domain/enums/mission_status.dart';

class MissionModel {
  final String id;
  final String type;
  final String statut;
  final String dateHeure;
  final String? codeConfirmation;
  final int photosCount;
  final String agentId;
  final String referenceId;
  final String? notesAgent;
  final String? raisonRefus;
  final double? latitude;
  final double? longitude;

  const MissionModel({
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

  factory MissionModel.fromEntity(Mission e) {
    return MissionModel(
      id: e.id,
      type: e.type.name,
      statut: e.statut.name,
      dateHeure: e.dateHeure.toIso8601String(),
      agentId: e.agentId,
      referenceId: e.referenceId,
      codeConfirmation: e.codeConfirmation,
      photosCount: e.photosCount,
      notesAgent: e.notesAgent,
      raisonRefus: e.raisonRefus,
      latitude: e.latitude,
      longitude: e.longitude,
    );
  }

  Mission toEntity() {
    return Mission(
      id: id,
      type: MissionType.values.firstWhere((t) => t.name == type),
      statut: MissionStatus.values.firstWhere((s) => s.name == statut),
      dateHeure: DateTime.parse(dateHeure),
      agentId: agentId,
      referenceId: referenceId,
      codeConfirmation: codeConfirmation,
      photosCount: photosCount,
      notesAgent: notesAgent,
      raisonRefus: raisonRefus,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'statut': statut,
        'dateHeure': dateHeure,
        'codeConfirmation': codeConfirmation,
        'photosCount': photosCount,
        'agentId': agentId,
        'referenceId': referenceId,
        'notesAgent': notesAgent,
        'raisonRefus': raisonRefus,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      statut: json['statut'] as String,
      dateHeure: json['dateHeure'] as String,
      agentId: json['agentId'] as String,
      referenceId: json['referenceId'] as String,
      codeConfirmation: json['codeConfirmation'] as String?,
      photosCount: json['photosCount'] as int? ?? 0,
      notesAgent: json['notesAgent'] as String?,
      raisonRefus: json['raisonRefus'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
EOF
echo "→ lib/data/models/mission_model.dart créé."

# ============================================================================
# 9. MODEL : LitigeModel
# ============================================================================
cat > lib/data/models/litige_model.dart << 'EOF'
import '../../domain/entities/litige.dart';
import '../../domain/enums/dispute_status.dart';

class LitigeModel {
  final String id;
  final String motif;
  final String statut;
  final String? decision;
  final double? montantRembourse;
  final String dateOuverture;
  final String commandeId;
  final String ouvertParUserId;
  final String? traiteParAdminId;

  const LitigeModel({
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

  factory LitigeModel.fromEntity(Litige e) {
    return LitigeModel(
      id: e.id,
      motif: e.motif,
      statut: e.statut.name,
      decision: e.decision,
      montantRembourse: e.montantRembourse,
      dateOuverture: e.dateOuverture.toIso8601String(),
      commandeId: e.commandeId,
      ouvertParUserId: e.ouvertParUserId,
      traiteParAdminId: e.traiteParAdminId,
    );
  }

  Litige toEntity() {
    return Litige(
      id: id,
      motif: motif,
      statut: DisputeStatus.values.firstWhere((s) => s.name == statut),
      decision: decision,
      montantRembourse: montantRembourse,
      dateOuverture: DateTime.parse(dateOuverture),
      commandeId: commandeId,
      ouvertParUserId: ouvertParUserId,
      traiteParAdminId: traiteParAdminId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'motif': motif,
        'statut': statut,
        'decision': decision,
        'montantRembourse': montantRembourse,
        'dateOuverture': dateOuverture,
        'commandeId': commandeId,
        'ouvertParUserId': ouvertParUserId,
        'traiteParAdminId': traiteParAdminId,
      };

  factory LitigeModel.fromJson(Map<String, dynamic> json) {
    return LitigeModel(
      id: json['id'] as String,
      motif: json['motif'] as String,
      statut: json['statut'] as String,
      decision: json['decision'] as String?,
      montantRembourse: (json['montantRembourse'] as num?)?.toDouble(),
      dateOuverture: json['dateOuverture'] as String,
      commandeId: json['commandeId'] as String,
      ouvertParUserId: json['ouvertParUserId'] as String,
      traiteParAdminId: json['traiteParAdminId'] as String?,
    );
  }
}
EOF
echo "→ lib/data/models/litige_model.dart créé."

# ============================================================================
# 10. MODEL : NotificationModel
# ============================================================================
cat > lib/data/models/notification_model.dart << 'EOF'
import '../../domain/entities/notification_entity.dart';
import '../../domain/enums/notification_type.dart';

class NotificationModel {
  final String id;
  final String message;
  final String type;
  final bool estLue;
  final String dateEnvoi;
  final String canal;
  final String destinataireId;
  final String? referenceId;

  const NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.dateEnvoi,
    required this.destinataireId,
    this.estLue = false,
    this.canal = 'push',
    this.referenceId,
  });

  factory NotificationModel.fromEntity(NotificationEntity e) {
    return NotificationModel(
      id: e.id,
      message: e.message,
      type: e.type.name,
      estLue: e.estLue,
      dateEnvoi: e.dateEnvoi.toIso8601String(),
      canal: e.canal.name,
      destinataireId: e.destinataireId,
      referenceId: e.referenceId,
    );
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      message: message,
      type: NotificationType.values.firstWhere((t) => t.name == type),
      estLue: estLue,
      dateEnvoi: DateTime.parse(dateEnvoi),
      canal: NotificationChannel.values.firstWhere((c) => c.name == canal),
      destinataireId: destinataireId,
      referenceId: referenceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'type': type,
        'estLue': estLue,
        'dateEnvoi': dateEnvoi,
        'canal': canal,
        'destinataireId': destinataireId,
        'referenceId': referenceId,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      estLue: json['estLue'] as bool? ?? false,
      dateEnvoi: json['dateEnvoi'] as String,
      canal: json['canal'] as String? ?? 'push',
      destinataireId: json['destinataireId'] as String,
      referenceId: json['referenceId'] as String?,
    );
  }
}
EOF
echo "→ lib/data/models/notification_model.dart créé."

# ============================================================================
# 11. MODEL : ConversationModel et MessageModel
# ============================================================================
cat > lib/data/models/conversation_model.dart << 'EOF'
import '../../domain/entities/conversation.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String? produitId;
  final String dernierMessage;
  final String dateDernierMessage;
  final int nombreNonLus;
  final bool estSupport;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    required this.dernierMessage,
    required this.dateDernierMessage,
    this.produitId,
    this.nombreNonLus = 0,
    this.estSupport = false,
  });

  factory ConversationModel.fromEntity(Conversation e) {
    return ConversationModel(
      id: e.id,
      participantIds: e.participantIds,
      produitId: e.produitId,
      dernierMessage: e.dernierMessage,
      dateDernierMessage: e.dateDernierMessage.toIso8601String(),
      nombreNonLus: e.nombreNonLus,
      estSupport: e.estSupport,
    );
  }

  Conversation toEntity() {
    return Conversation(
      id: id,
      participantIds: participantIds,
      produitId: produitId,
      dernierMessage: dernierMessage,
      dateDernierMessage: DateTime.parse(dateDernierMessage),
      nombreNonLus: nombreNonLus,
      estSupport: estSupport,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'produitId': produitId,
        'dernierMessage': dernierMessage,
        'dateDernierMessage': dateDernierMessage,
        'nombreNonLus': nombreNonLus,
        'estSupport': estSupport,
      };

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      produitId: json['produitId'] as String?,
      dernierMessage: json['dernierMessage'] as String,
      dateDernierMessage: json['dateDernierMessage'] as String,
      nombreNonLus: json['nombreNonLus'] as int? ?? 0,
      estSupport: json['estSupport'] as bool? ?? false,
    );
  }
}
EOF
echo "→ lib/data/models/conversation_model.dart créé."

cat > lib/data/models/message_model.dart << 'EOF'
import '../../domain/entities/message.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String contenu;
  final String dateEnvoi;
  final bool estLu;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.contenu,
    required this.dateEnvoi,
    this.estLu = false,
  });

  factory MessageModel.fromEntity(Message e) {
    return MessageModel(
      id: e.id,
      conversationId: e.conversationId,
      expediteurId: e.expediteurId,
      contenu: e.contenu,
      dateEnvoi: e.dateEnvoi.toIso8601String(),
      estLu: e.estLu,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      conversationId: conversationId,
      expediteurId: expediteurId,
      contenu: contenu,
      dateEnvoi: DateTime.parse(dateEnvoi),
      estLu: estLu,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'expediteurId': expediteurId,
        'contenu': contenu,
        'dateEnvoi': dateEnvoi,
        'estLu': estLu,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      expediteurId: json['expediteurId'] as String,
      contenu: json['contenu'] as String,
      dateEnvoi: json['dateEnvoi'] as String,
      estLu: json['estLu'] as bool? ?? false,
    );
  }
}
EOF
echo "→ lib/data/models/message_model.dart créé."

echo ""
echo "============================================================"
echo "  ✔ Script 04 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • 12 Models JSON (un par entité du domaine), chacun avec"
echo "    toJson/fromJson et toEntity/fromEntity."
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 05 : le"
echo "  service Hive (initialisation, ouverture des box) et les"
echo "  repositories locaux génériques qui utilisent ces Models."
echo ""

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
  final String categorieId;
  final int quantite;
  final String descriptionInitiale;
  final double prixSouhaite;
  final String? missionId;
  final String? raisonRefus;
  final double? latitude;
  final double? longitude;

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
    required this.categorieId,
    required this.quantite,
    required this.descriptionInitiale,
    required this.prixSouhaite,
    this.missionId,
    this.raisonRefus,
    this.latitude,
    this.longitude,
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
      categorieId: e.categorieId,
      quantite: e.quantite,
      descriptionInitiale: e.descriptionInitiale,
      prixSouhaite: e.prixSouhaite,
      missionId: e.missionId,
      raisonRefus: e.raisonRefus,
      latitude: e.latitude,
      longitude: e.longitude,
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
      categorieId: categorieId,
      quantite: quantite,
      descriptionInitiale: descriptionInitiale,
      prixSouhaite: prixSouhaite,
      missionId: missionId,
      raisonRefus: raisonRefus,
      latitude: latitude,
      longitude: longitude,
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
        'categorieId': categorieId,
        'quantite': quantite,
        'descriptionInitiale': descriptionInitiale,
        'prixSouhaite': prixSouhaite,
        'missionId': missionId,
        'raisonRefus': raisonRefus,
        'latitude': latitude,
        'longitude': longitude,
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
      categorieId: json['categorieId'] as String? ?? '',
      quantite: json['quantite'] as int,
      descriptionInitiale: json['descriptionInitiale'] as String,
      prixSouhaite: (json['prixSouhaite'] as num).toDouble(),
      missionId: json['missionId'] as String?,
      raisonRefus: json['raisonRefus'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

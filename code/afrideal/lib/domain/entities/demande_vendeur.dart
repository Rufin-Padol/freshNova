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
  final String categorieId;
  final int quantite;
  final String descriptionInitiale;
  final double prixSouhaite;

  /// Identifiant de la mission créée une fois un agent assigné.
  final String? missionId;

  /// Raison du refus, si applicable.
  final String? raisonRefus;

  /// Position réelle choisie par le vendeur sur la carte à la
  /// soumission, en complément de l'adresse texte — permet à l'agent
  /// de s'y rendre avec une navigation précise plutôt qu'une simple
  /// description.
  final double? latitude;
  final double? longitude;

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
    required this.categorieId,
    required this.quantite,
    required this.descriptionInitiale,
    required this.prixSouhaite,
    this.missionId,
    this.raisonRefus,
    this.latitude,
    this.longitude,
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
    String? categorieId,
    int? quantite,
    String? descriptionInitiale,
    double? prixSouhaite,
    String? missionId,
    String? raisonRefus,
    double? latitude,
    double? longitude,
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
      categorieId: categorieId ?? this.categorieId,
      quantite: quantite ?? this.quantite,
      descriptionInitiale: descriptionInitiale ?? this.descriptionInitiale,
      prixSouhaite: prixSouhaite ?? this.prixSouhaite,
      missionId: missionId ?? this.missionId,
      raisonRefus: raisonRefus ?? this.raisonRefus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
        categorieId,
        quantite,
        descriptionInitiale,
        prixSouhaite,
        missionId,
        raisonRefus,
        latitude,
        longitude,
      ];
}

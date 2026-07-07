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
  final String? dimensions;
  final String? proprietaireId;
  final String? missionId;

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
    this.dimensions,
    this.proprietaireId,
    this.missionId,
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
      dimensions: e.dimensions,
      proprietaireId: e.proprietaireId,
      missionId: e.missionId,
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
      dimensions: dimensions,
      proprietaireId: proprietaireId,
      missionId: missionId,
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
        'dimensions': dimensions,
        'proprietaireId': proprietaireId,
        'missionId': missionId,
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
      dimensions: json['dimensions'] as String?,
      proprietaireId: json['proprietaireId'] as String?,
      missionId: json['missionId'] as String?,
    );
  }
}

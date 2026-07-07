import '../../domain/entities/proprietaire.dart';

class ProprietaireModel {
  final String id;
  final String nom;
  final String telephone;
  final String? ville;
  final String dateCreation;

  const ProprietaireModel({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.dateCreation,
    this.ville,
  });

  factory ProprietaireModel.fromEntity(Proprietaire e) {
    return ProprietaireModel(
      id: e.id,
      nom: e.nom,
      telephone: e.telephone,
      ville: e.ville,
      dateCreation: e.dateCreation.toIso8601String(),
    );
  }

  Proprietaire toEntity() {
    return Proprietaire(
      id: id,
      nom: nom,
      telephone: telephone,
      ville: ville,
      dateCreation: DateTime.parse(dateCreation),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'telephone': telephone,
        'ville': ville,
        'dateCreation': dateCreation,
      };

  factory ProprietaireModel.fromJson(Map<String, dynamic> json) {
    return ProprietaireModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      ville: json['ville'] as String?,
      dateCreation: json['dateCreation'] as String,
    );
  }
}

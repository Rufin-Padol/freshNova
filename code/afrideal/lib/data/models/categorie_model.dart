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

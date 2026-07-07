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

  /// Taux de commission (en pourcentage) appliqué aux produits de
  /// cette catégorie — configurable par le Super Admin, remplace la
  /// constante fixe utilisée auparavant pour toutes les catégories.
  final double tauxCommission;

  const Categorie({
    required this.id,
    required this.nom,
    this.iconeAsset,
    this.parentId,
    this.ordreAffichage = 0,
    this.tauxCommission = 10.0,
  });

  bool get estSousCategorie => parentId != null;

  Categorie copyWith({
    String? id,
    String? nom,
    String? iconeAsset,
    String? parentId,
    int? ordreAffichage,
    double? tauxCommission,
  }) {
    return Categorie(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      iconeAsset: iconeAsset ?? this.iconeAsset,
      parentId: parentId ?? this.parentId,
      ordreAffichage: ordreAffichage ?? this.ordreAffichage,
      tauxCommission: tauxCommission ?? this.tauxCommission,
    );
  }

  @override
  List<Object?> get props =>
      [id, nom, iconeAsset, parentId, ordreAffichage, tauxCommission];
}

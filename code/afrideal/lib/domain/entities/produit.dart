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

  /// Dimensions/taille du produit, en texte libre (ex. "120x60x75 cm"),
  /// renseignées par l'agent lors de la collecte.
  final String? dimensions;

  /// Propriétaire identifié par l'agent lors de la collecte (registre
  /// [Proprietaire]) — jamais exposé à l'acheteur (anonymat).
  final String? proprietaireId;

  /// Mission de collecte à l'origine de ce produit — lien direct et
  /// fiable pour retrouver le produit d'une mission donnée (plutôt que
  /// de déduire par élimination via agentId + statut).
  final String? missionId;

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
    this.dimensions,
    this.proprietaireId,
    this.missionId,
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
    String? dimensions,
    String? proprietaireId,
    String? missionId,
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
      dimensions: dimensions ?? this.dimensions,
      proprietaireId: proprietaireId ?? this.proprietaireId,
      missionId: missionId ?? this.missionId,
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
        dimensions,
        proprietaireId,
        missionId,
      ];
}

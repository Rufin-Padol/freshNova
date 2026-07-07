import 'package:equatable/equatable.dart';

/// Entité métier Propriétaire — la personne physique rencontrée par
/// l'agent terrain lors de la collecte, propriétaire réel du bien.
///
/// Volontairement indépendante des comptes [Utilisateur] (rôle
/// vendeur) : un propriétaire n'a pas besoin d'installer l'application
/// pour vendre — l'agent peut le rechercher parmi les propriétaires
/// déjà connus de la plateforme, ou en créer un nouveau sur place.
/// Ces informations restent internes à AfriDeal : l'acheteur ne les
/// voit jamais (voir principe d'anonymat du cahier des charges).
class Proprietaire extends Equatable {
  final String id;
  final String nom;
  final String telephone;
  final String? ville;
  final DateTime dateCreation;

  const Proprietaire({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.dateCreation,
    this.ville,
  });

  Proprietaire copyWith({
    String? id,
    String? nom,
    String? telephone,
    String? ville,
    DateTime? dateCreation,
  }) {
    return Proprietaire(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      ville: ville ?? this.ville,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  List<Object?> get props => [id, nom, telephone, ville, dateCreation];
}

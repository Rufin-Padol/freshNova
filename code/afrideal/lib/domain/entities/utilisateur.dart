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

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

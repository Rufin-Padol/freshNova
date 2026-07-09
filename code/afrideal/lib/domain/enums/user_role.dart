/// Les rôles distincts de la plateforme. Il n'existe pas de rôle
/// "vendeur" séparé : un Acheteur peut aussi bien acheter que
/// soumettre un bien à la vente depuis son profil — c'est TrustNova
/// qui met le produit en vente après vérification par un agent, pas
/// l'utilisateur lui-même. Seuls les rôles internes (agent terrain,
/// admin, super admin) ont leur propre espace applicatif dédié.
enum UserRole {
  acheteur,
  agentTerrain,
  admin,
  superAdmin;

  String get label {
    switch (this) {
      case UserRole.acheteur:
        return 'Membre';
      case UserRole.agentTerrain:
        return 'Agent terrain';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.superAdmin:
        return 'Super administrateur';
    }
  }

  /// Indique si ce rôle a accès au panneau web (Admin / Super Admin),
  /// par opposition aux rôles mobiles (Acheteur, Agent).
  bool get isWebRole => this == UserRole.admin || this == UserRole.superAdmin;
}

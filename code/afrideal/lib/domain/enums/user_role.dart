/// Les 5 rôles distincts de la plateforme, conformes au cahier des
/// charges. Chaque rôle a son propre espace applicatif et ses propres
/// permissions : un Acheteur ne voit jamais les écrans Agent, etc.
enum UserRole {
  acheteur,
  vendeur,
  agentTerrain,
  admin,
  superAdmin;

  String get label {
    switch (this) {
      case UserRole.acheteur:
        return 'Acheteur';
      case UserRole.vendeur:
        return 'Vendeur';
      case UserRole.agentTerrain:
        return 'Agent terrain';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.superAdmin:
        return 'Super administrateur';
    }
  }

  /// Indique si ce rôle a accès au panneau web (Admin / Super Admin),
  /// par opposition aux rôles mobiles (Acheteur, Vendeur, Agent).
  bool get isWebRole => this == UserRole.admin || this == UserRole.superAdmin;
}

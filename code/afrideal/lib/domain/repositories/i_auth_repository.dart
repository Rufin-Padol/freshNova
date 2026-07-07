import '../entities/utilisateur.dart';

/// Contrat d'authentification, indépendant du mode (local ou API).
///
/// En mode local, [login] vérifie les identifiants contre les comptes
/// de démonstration stockés dans Hive. En mode API, il enverra une
/// requête au serveur Spring Boot et stockera le token JWT renvoyé.
abstract class IAuthRepository {
  Future<Utilisateur?> login({
    required String telephone,
    required String motDePasse,
  });

  Future<Utilisateur> register(Utilisateur utilisateur, String motDePasse);

  /// Crée un compte SANS connecter la session sur ce nouveau compte —
  /// utilisé par le Super Admin pour créer un compte Admin sans se
  /// retrouver lui-même déconnecté et reconnecté sur ce nouveau compte
  /// (contrairement à [register], pensé pour l'auto-inscription).
  Future<Utilisateur> creerCompteSansConnexion(Utilisateur utilisateur, String motDePasse);

  Future<void> logout();

  /// Retourne l'utilisateur actuellement connecté, ou null si personne
  /// n'est connecté (utile pour restaurer la session au lancement).
  Future<Utilisateur?> getCurrentUser();

  /// Retourne la liste des comptes de démonstration disponibles
  /// (Acheteur test, Vendeur test, Agent test, Admin test, Super
  /// Admin test), utilisée par l'écran de sélection de compte démo.
  /// Cette méthode n'a de sens qu'en mode local ; en mode API elle
  /// renverra simplement une liste vide.
  Future<List<Utilisateur>> getDemoAccounts();

  /// Connecte directement un compte de démonstration par son
  /// identifiant, sans vérification de mot de passe. N'a de sens
  /// qu'en mode local (voir choix validé : sélection de compte démo
  /// plutôt que saisie d'identifiants). En mode API, cette méthode
  /// lèvera une UnimplementedError si jamais appelée par erreur.
  Future<Utilisateur?> loginAsDemoAccount(String userId);
}

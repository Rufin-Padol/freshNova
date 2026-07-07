/// Exception métier de base de l'application.
///
/// Toute erreur prévisible (donnée manquante, règle métier violée, échec
/// réseau...) doit être levée sous forme d'une sous-classe de
/// [AppException] plutôt qu'une Exception générique. Cela permet à la
/// couche présentation d'afficher un message clair et adapté à
/// l'utilisateur, plutôt qu'un message technique incompréhensible.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Levée quand une ressource demandée n'existe pas
/// (ex: produit déjà supprimé, commande introuvable).
class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'Élément introuvable.',
  ]) : super(message, code: 'NOT_FOUND');
}

/// Levée quand une règle métier empêche l'opération
/// (ex: tenter de payer un produit déjà vendu).
class BusinessRuleException extends AppException {
  const BusinessRuleException(super.message) : super(code: 'BUSINESS_RULE');
}

/// Levée lors d'un échec de validation de formulaire ou de données.
class ValidationException extends AppException {
  const ValidationException(super.message) : super(code: 'VALIDATION');
}

/// Levée lors d'un problème de connexion réseau (mode API uniquement).
class NetworkException extends AppException {
  const NetworkException([
    String message = 'Connexion impossible. Vérifiez votre réseau.',
  ]) : super(message, code: 'NETWORK');
}

/// Levée lorsque le serveur répond avec une erreur (mode API uniquement).
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    String message, {
    this.statusCode,
  }) : super(message, code: 'SERVER');
}

/// Levée lors d'un échec d'authentification
/// (identifiants invalides, session expirée).
class AuthException extends AppException {
  const AuthException([
    String message = 'Authentification requise.',
  ]) : super(message, code: 'AUTH');
}

/// Levée lors d'un échec de lecture/écriture dans le stockage local.
class StorageException extends AppException {
  const StorageException([
    String message = 'Erreur de stockage local.',
  ]) : super(message, code: 'STORAGE');
}

/// Convertit n'importe quelle erreur capturée (catch) en message lisible
/// pour l'utilisateur. Utilisé en dernier recours dans les blocs
/// try/catch des providers, pour ne jamais laisser fuiter une erreur
/// technique brute (stack trace Dart) jusqu'à l'écran.
String friendlyErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return 'Une erreur inattendue est survenue. Veuillez réessayer.';
}

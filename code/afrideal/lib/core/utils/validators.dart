/// Validateurs de champs de formulaire réutilisés dans toute l'application.
///
/// Chaque méthode renvoie `null` si la valeur est valide, ou un message
/// d'erreur en français adapté à l'utilisateur si elle ne l'est pas.
/// Compatible directement avec la propriété `validator` des TextFormField.
class Validators {
  Validators._();

  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est obligatoire.';
    }
    return null;
  }

  /// Valide un numéro de téléphone camerounais.
  /// Accepte les formats : 6XXXXXXXX, +2376XXXXXXXX, 2376XXXXXXXX.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est obligatoire.';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    final pattern = RegExp(r'^(\+?237)?[26]\d{8}$');
    if (!pattern.hasMatch(cleaned)) {
      return 'Numéro de téléphone invalide.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire.';
    }
    if (value.length < 4) {
      return 'Le mot de passe doit contenir au moins 4 caractères.';
    }
    return null;
  }

  /// Valide qu'un prix saisi est un nombre strictement positif.
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prix est obligatoire.';
    }
    final parsed = num.tryParse(value.replaceAll(' ', ''));
    if (parsed == null || parsed <= 0) {
      return 'Veuillez saisir un prix valide.';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().length < min) {
      return '$fieldName doit contenir au moins $min caractères.';
    }
    return null;
  }
}

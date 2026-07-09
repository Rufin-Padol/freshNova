import 'svg_illustration_base.dart';

/// Illustration "confiance et sécurité" : bouclier avec coche,
/// thème central de l'identité TrustNova, utilisée sur l'écran
/// d'accueil et l'onboarding.
class TrustShieldIllustration extends SvgIllustrationBase {
  const TrustShieldIllustration({super.key, super.size});

  @override
  String get svgContent => '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#7C3AED"/>
      <stop offset="100%" stop-color="#2563EB"/>
    </linearGradient>
  </defs>
  <path d="M100 20 L165 45 V95 C165 135 138 165 100 180 C62 165 35 135 35 95 V45 Z" fill="url(#g1)"/>
  <path d="M80 100 L94 114 L122 84" stroke="#FFFFFF" stroke-width="9" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';
}

/// Illustration "vérification d'agent" : silhouette avec loupe,
/// utilisée pour représenter le processus de vérification terrain.
class VerificationIllustration extends SvgIllustrationBase {
  const VerificationIllustration({super.key, super.size});

  @override
  String get svgContent => '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <circle cx="100" cy="100" r="80" fill="#EDE9FE"/>
  <rect x="70" y="60" width="60" height="80" rx="6" fill="#FFFFFF" stroke="#7C3AED" stroke-width="4"/>
  <line x1="82" y1="80" x2="118" y2="80" stroke="#C4B5FD" stroke-width="5" stroke-linecap="round"/>
  <line x1="82" y1="95" x2="118" y2="95" stroke="#C4B5FD" stroke-width="5" stroke-linecap="round"/>
  <line x1="82" y1="110" x2="105" y2="110" stroke="#C4B5FD" stroke-width="5" stroke-linecap="round"/>
  <circle cx="128" cy="128" r="22" fill="#FFFFFF" stroke="#2563EB" stroke-width="6"/>
  <line x1="144" y1="144" x2="160" y2="160" stroke="#2563EB" stroke-width="7" stroke-linecap="round"/>
</svg>
''';
}

/// Illustration de paiement sécurisé (Mobile Money), utilisée sur
/// l'écran de paiement et de confirmation d'achat.
class SecurePaymentIllustration extends SvgIllustrationBase {
  const SecurePaymentIllustration({super.key, super.size});

  @override
  String get svgContent => '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="g2" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#7C3AED"/>
      <stop offset="100%" stop-color="#2563EB"/>
    </linearGradient>
  </defs>
  <rect x="40" y="65" width="120" height="80" rx="12" fill="url(#g2)"/>
  <rect x="40" y="85" width="120" height="14" fill="#1F2937" opacity="0.25"/>
  <rect x="55" y="115" width="40" height="10" rx="5" fill="#FFFFFF" opacity="0.85"/>
  <circle cx="145" cy="50" r="22" fill="#F59E0B"/>
  <path d="M136 50 L143 57 L156 42" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';
}

/// Illustration "succès" générique (grosse coche dans un cercle),
/// utilisée sur les écrans de confirmation (commande passée, demande
/// envoyée, mission terminée...).
class SuccessIllustration extends SvgIllustrationBase {
  const SuccessIllustration({super.key, super.size});

  @override
  String get svgContent => '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <circle cx="100" cy="100" r="78" fill="#D1FAE5"/>
  <circle cx="100" cy="100" r="55" fill="#059669"/>
  <path d="M75 100 L92 117 L128 80" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';
}

/// Illustration "boîte vide", utilisée pour les listes vides
/// (aucune commande, aucun favori, aucune mission...).
class EmptyBoxIllustration extends SvgIllustrationBase {
  const EmptyBoxIllustration({super.key, super.size});

  @override
  String get svgContent => '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="100" cy="150" rx="55" ry="10" fill="#F3F4F6"/>
  <path d="M55 90 L100 70 L145 90 V135 L100 155 L55 135 Z" fill="#EDE9FE"/>
  <path d="M55 90 L100 110 L145 90" stroke="#C4B5FD" stroke-width="5" fill="none" stroke-linejoin="round"/>
  <line x1="100" y1="110" x2="100" y2="155" stroke="#C4B5FD" stroke-width="5"/>
</svg>
''';
}

/// Illustration "localisation", utilisée sur les écrans de mission
/// agent et de suivi de livraison.
class LocationIllustration extends SvgIllustrationBase {
  const LocationIllustration({super.key, super.size});

  @override
  String get svgContent => '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <circle cx="100" cy="190" rx="40" ry="8" fill="#F3F4F6"/>
  <path d="M100 30 C70 30 48 52 48 82 C48 122 100 175 100 175 C100 175 152 122 152 82 C152 52 130 30 100 30 Z" fill="#7C3AED"/>
  <circle cx="100" cy="82" r="26" fill="#FFFFFF"/>
  <circle cx="100" cy="82" r="12" fill="#2563EB"/>
</svg>
''';
}

/// Illustration "messagerie", utilisée pour l'état vide de l'écran
/// de conversation et l'onboarding du support.
class MessageIllustration extends SvgIllustrationBase {
  const MessageIllustration({super.key, super.size});

  @override
  String get svgContent => '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <rect x="40" y="55" width="120" height="80" rx="16" fill="#EFF6FF"/>
  <path d="M70 135 L70 155 L95 135 Z" fill="#EFF6FF"/>
  <line x1="62" y1="80" x2="138" y2="80" stroke="#93C5FD" stroke-width="6" stroke-linecap="round"/>
  <line x1="62" y1="98" x2="120" y2="98" stroke="#93C5FD" stroke-width="6" stroke-linecap="round"/>
  <line x1="62" y1="116" x2="105" y2="116" stroke="#93C5FD" stroke-width="6" stroke-linecap="round"/>
</svg>
''';
}

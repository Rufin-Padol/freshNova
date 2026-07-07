import 'package:flutter/material.dart';

/// Système d'espacement et de dimensions.
///
/// Utiliser ces constantes partout évite les écrans "bricolés" avec des
/// valeurs magiques (ex: padding: 13.5) et garantit une cohérence visuelle
/// stricte sur l'ensemble de l'application.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get fullRadius => BorderRadius.circular(full);
}

/// Ombres standardisées. Volontairement discrètes : le design AfriDeal
/// privilégie les bordures fines et les surfaces claires plutôt que des
/// ombres marquées, pour rester sobre et rapide à dessiner (important
/// pour la fluidité sur des appareils d'entrée de gamme).
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Durées d'animation standardisées. Des transitions courtes et nettes
/// donnent une sensation de rapidité, essentielle sur réseau lent.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

import 'package:flutter/material.dart';

/// Transitions de navigation personnalisées pour TrustNova.
///
/// Deux variantes selon le contexte :
///   - [fadeSlide] : transition principale (fondu + glissement léger
///     vers le haut). Utilisée pour les navigations d'écran principal
///     (boutique → fiche produit). Dure 250ms — suffisamment rapide
///     pour ne jamais sembler lente, même sur appareil d'entrée de
///     gamme.
///   - [fade] : fondu simple. Utilisée pour les transitions de haut
///     niveau (changement de section via la navigation inférieure)
///     où un glissement serait déroutant.
class AppTransitions {
  AppTransitions._();

  static Widget fadeSlide(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.03);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(tween),
        child: child,
      ),
    );
  }

  static Widget fade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

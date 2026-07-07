import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Classe de base pour toutes les illustrations SVG de l'application.
///
/// Centralise le rendu via SvgPicture.string et l'utilisation de
/// colorFilter (et non la propriété `color`, dépréciée), garantissant
/// un comportement homogène et à jour sur toutes les illustrations.
abstract class SvgIllustrationBase extends StatelessWidget {
  final double size;

  const SvgIllustrationBase({super.key, this.size = 120});

  /// Le contenu SVG brut (balises <svg>...</svg>) à afficher.
  String get svgContent;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svgContent,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

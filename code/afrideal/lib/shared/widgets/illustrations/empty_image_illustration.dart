import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

/// Illustration de remplacement affichée quand une photo produit
/// n'est pas disponible ou échoue à charger. Évite d'afficher une
/// icône d'erreur générique disgracieuse.
class EmptyImageIllustration extends StatelessWidget {
  const EmptyImageIllustration({super.key});

  static const String _svg = '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <rect width="200" height="200" fill="#F3F4F6"/>
  <rect x="50" y="60" width="100" height="80" rx="8" fill="#E5E7EB"/>
  <circle cx="75" cy="85" r="9" fill="#D1D5DB"/>
  <path d="M50 125 L80 100 L100 118 L130 90 L150 110 V132 A8 8 0 0 1 142 140 H58 A8 8 0 0 1 50 132 Z" fill="#D1D5DB"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray100,
      alignment: Alignment.center,
      child: SvgPicture.string(_svg, width: 56, height: 56),
    );
  }
}

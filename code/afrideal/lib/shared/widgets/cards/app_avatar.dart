import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Avatar circulaire d'utilisateur. Affiche la photo si disponible,
/// sinon un fond dégradé avec les initiales — jamais d'icône
/// générique grise, pour garder une identité visuelle chaleureuse
/// même sans photo de profil.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initiales;
  final double size;

  const AppAvatar({
    super.key,
    required this.initiales,
    this.photoUrl,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitiales(),
        ),
      );
    }
    return _buildInitiales();
  }

  Widget _buildInitiales() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initiales,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.white,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

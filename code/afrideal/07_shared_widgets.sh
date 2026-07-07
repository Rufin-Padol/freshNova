#!/bin/bash
# ============================================================================
# SCRIPT 07 — Widgets partagés réutilisables
# Projet : AfriDeal — Plateforme de revente de seconde main (Cameroun)
# ============================================================================
#
# CE QUE FAIT CE SCRIPT :
#   Crée la bibliothèque de composants visuels communs à TOUTE
#   l'application, dans lib/shared/widgets. Chaque écran créé dans les
#   scripts suivants utilisera exclusivement ces composants plutôt que
#   de redéfinir des boutons/cartes/champs à chaque fois — ce qui
#   garantit une cohérence visuelle stricte et évite la duplication.
#
# CONTENU :
#   • buttons/    → AppPrimaryButton, AppSecondaryButton, AppIconButton
#   • inputs/     → AppTextField, AppSearchField
#   • cards/      → ProductCard, StatusBadge, AppAvatar
#   • feedback/   → AppLoadingIndicator, AppSnackbar (helpers)
#   • illustrations/ → bibliothèque d'illustrations SVG vectorielles
#                       (zéro emoji, comme exigé), générées en code
#                       Dart via SvgPicture.string — pas de fichiers
#                       .svg externes à gérer manuellement.
#   • layout/     → AppScaffold (structure d'écran standard),
#                    SectionHeader, EmptySpace
#
# POURQUOI DES SVG EN CHAÎNE DE CARACTÈRES PLUTÔT QU'EN FICHIERS ?
#   En les définissant directement en Dart (SvgPicture.string), un
#   script bash peut les livrer sans avoir besoin de créer et
#   référencer des dizaines de fichiers .svg séparés dans pubspec.yaml.
#   Le résultat visuel est strictement identique.
#
# COMMENT EXÉCUTER CE SCRIPT :
#   bash 07_shared_widgets.sh
#
# CE QUE VOUS DEVEZ VOIR SI TOUT FONCTIONNE :
#   Le message final "✔ Script 07 terminé avec succès."
# ============================================================================

set -e

echo "============================================================"
echo "  AfriDeal — Script 07/14 : Widgets partagés"
echo "============================================================"

if [ ! -d "lib/shared/widgets" ]; then
  echo "ERREUR : lib/shared/widgets introuvable. Avez-vous exécuté le script 01 ?"
  exit 1
fi

mkdir -p lib/shared/widgets/buttons
mkdir -p lib/shared/widgets/inputs
mkdir -p lib/shared/widgets/cards
mkdir -p lib/shared/widgets/feedback
mkdir -p lib/shared/widgets/illustrations
mkdir -p lib/shared/widgets/layout

# ============================================================================
# 1. BOUTONS
# ============================================================================
cat > lib/shared/widgets/buttons/app_primary_button.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Bouton d'action principal de l'application (fond violet plein).
/// Gère nativement un état de chargement, pour éviter à chaque écran
/// de réimplémenter sa propre logique de bouton "en cours".
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label),
              ],
            ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
EOF
echo "→ lib/shared/widgets/buttons/app_primary_button.dart créé."

cat > lib/shared/widgets/buttons/app_secondary_button.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_dimens.dart';

/// Bouton d'action secondaire (contour violet, fond transparent).
/// Utilisé pour les actions de moindre priorité ("Annuler", "Plus tard").
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(label),
        ],
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
EOF
echo "→ lib/shared/widgets/buttons/app_secondary_button.dart créé."

cat > lib/shared/widgets/buttons/app_icon_button.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Bouton circulaire avec icône, utilisé dans les barres d'application
/// et les actions flottantes secondaires (favoris, partage...).
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor ?? AppColors.gray100,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: iconColor ?? AppColors.gray700,
            size: size * 0.5,
          ),
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}
EOF
echo "→ lib/shared/widgets/buttons/app_icon_button.dart créé."

# ============================================================================
# 2. CHAMPS DE SAISIE
# ============================================================================
cat > lib/shared/widgets/inputs/app_text_field.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Champ de texte standardisé de l'application, avec libellé optionnel
/// au-dessus (plutôt qu'un label flottant), pour une lisibilité
/// maximale même sur petit écran.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final void Function(String)? onChanged;
  final String? initialValue;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          enabled: enabled,
          onChanged: onChanged,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.black),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.gray400, size: 20)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
EOF
echo "→ lib/shared/widgets/inputs/app_text_field.dart créé."

cat > lib/shared/widgets/inputs/app_search_field.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Champ de recherche standardisé, utilisé en haut de la boutique et
/// des écrans de catalogue/listing.
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final void Function(String)? onChanged;
  final VoidCallback? onFilterTap;

  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Rechercher un produit...',
    this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.lg),
          const Icon(Icons.search_rounded, color: AppColors.gray400, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
            ),
          ),
          if (onFilterTap != null)
            IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune_rounded, color: AppColors.violet),
            ),
        ],
      ),
    );
  }
}
EOF
echo "→ lib/shared/widgets/inputs/app_search_field.dart créé."

# ============================================================================
# 3. CARTES ET BADGES
# ============================================================================
cat > lib/shared/widgets/cards/status_badge.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Badge coloré affichant un statut (produit, commande, mission...).
/// La couleur est entièrement déterminée par l'appelant, ce qui
/// permet de réutiliser ce SEUL widget pour tous les types de statuts
/// de l'application (chacun ayant déjà sa propre couleur définie dans
/// son enum, voir script 03).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
EOF
echo "→ lib/shared/widgets/cards/status_badge.dart créé."

cat > lib/shared/widgets/cards/app_avatar.dart << 'EOF'
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
EOF
echo "→ lib/shared/widgets/cards/app_avatar.dart créé."

cat > lib/shared/widgets/cards/product_card.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../illustrations/empty_image_illustration.dart';

/// Carte produit affichée dans les grilles de la boutique, des
/// favoris, et des listes vendeur/agent.
///
/// Volontairement compacte : seules les informations essentielles à
/// la décision d'achat sont visibles (photo, titre, prix, localisation).
/// Le détail complet n'apparaît que sur la fiche produit.
class ProductCard extends StatelessWidget {
  final String titre;
  final double prix;
  final String? photoUrl;
  final String localisation;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool estFavori;

  const ProductCard({
    super.key,
    required this.titre,
    required this.prix,
    required this.localisation,
    required this.onTap,
    this.photoUrl,
    this.onFavoriteTap,
    this.estFavori = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.gray200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: photoUrl != null && photoUrl!.isNotEmpty
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const EmptyImageIllustration(),
                        )
                      : const EmptyImageIllustration(),
                ),
                if (onFavoriteTap != null)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          estFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: estFavori ? AppColors.danger : AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(prix),
                    style: AppTypography.titleMedium.copyWith(color: AppColors.violet),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.gray400),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          localisation,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF
echo "→ lib/shared/widgets/cards/product_card.dart créé."

cat > lib/shared/widgets/cards/info_row.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Ligne d'information libellé/valeur, utilisée dans les écrans de
/// détail (fiche produit, détail commande, détail mission...) pour
/// présenter des informations structurées de façon cohérente partout
/// dans l'application.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.gray400),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.bodyLarge.copyWith(color: AppColors.black)),
            ],
          ),
        ),
      ],
    );
  }
}
EOF
echo "→ lib/shared/widgets/cards/info_row.dart créé."

# ============================================================================
# 4. FEEDBACK (chargement, snackbars)
# ============================================================================
cat > lib/shared/widgets/feedback/app_loading_indicator.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Indicateur de chargement standardisé, centré dans son espace
/// disponible. Utilisé à la place du CircularProgressIndicator brut
/// pour garantir une couleur et une taille cohérentes partout.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;

  const AppLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: AppColors.gray500)),
          ],
        ],
      ),
    );
  }
}
EOF
echo "→ lib/shared/widgets/feedback/app_loading_indicator.dart créé."

cat > lib/shared/widgets/feedback/app_snackbar.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Fonctions utilitaires pour afficher des messages temporaires
/// cohérents dans toute l'application (succès, erreur, information),
/// plutôt que de construire un SnackBar différemment à chaque écran.
class AppSnackbar {
  AppSnackbar._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.danger, Icons.error_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.blue, Icons.info_rounded);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
EOF
echo "→ lib/shared/widgets/feedback/app_snackbar.dart créé."

# ============================================================================
# 5. ILLUSTRATIONS SVG (vectorielles, zéro emoji)
# ============================================================================
cat > lib/shared/widgets/illustrations/svg_illustration_base.dart << 'EOF'
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
EOF
echo "→ lib/shared/widgets/illustrations/svg_illustration_base.dart créé."

cat > lib/shared/widgets/illustrations/empty_image_illustration.dart << 'EOF'
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
EOF
echo "→ lib/shared/widgets/illustrations/empty_image_illustration.dart créé."

cat > lib/shared/widgets/illustrations/onboarding_illustrations.dart << 'EOF'
import 'svg_illustration_base.dart';

/// Illustration "confiance et sécurité" : bouclier avec coche,
/// thème central de l'identité AfriDeal, utilisée sur l'écran
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
EOF
echo "→ lib/shared/widgets/illustrations/onboarding_illustrations.dart créé."

# ============================================================================
# 6. LAYOUT — structure d'écran standard
# ============================================================================
cat > lib/shared/widgets/layout/app_scaffold.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Structure d'écran standardisée, enveloppant un Scaffold classique
/// avec les réglages cohérents pour toute l'application (couleur de
/// fond, comportement du clavier...).
///
/// Utiliser ce widget plutôt que Scaffold directement garantit que
/// tout changement global de structure d'écran (ex: ajout d'une
/// bannière "Mode hors-ligne") peut se faire en un seul endroit.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool safeArea;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.safeArea = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = safeArea ? SafeArea(child: body) : body;
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: true,
    );
  }
}
EOF
echo "→ lib/shared/widgets/layout/app_scaffold.dart créé."

cat > lib/shared/widgets/layout/section_header.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// En-tête de section avec titre et action optionnelle ("Voir tout"),
/// utilisé pour structurer les écrans à plusieurs sections (accueil
/// boutique : Catégories, Annonces récentes...).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headline),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.violet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
EOF
echo "→ lib/shared/widgets/layout/section_header.dart créé."

cat > lib/shared/widgets/layout/progress_steps.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Barre de progression par étapes, utilisée pour visualiser le cycle
/// de vie d'un produit ou d'une mission (ex: Soumis → Collecté →
/// En vente → Livré), et pour les formulaires en plusieurs étapes
/// (soumission vendeur en 3 étapes).
class ProgressSteps extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const ProgressSteps({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepBefore = i ~/ 2;
          final estFranchi = stepBefore < currentIndex;
          return Expanded(
            child: Container(
              height: 3,
              color: estFranchi ? AppColors.violet : AppColors.gray200,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final estActif = stepIndex == currentIndex;
        final estComplete = stepIndex < currentIndex;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: estComplete || estActif ? AppColors.violet : AppColors.gray200,
              ),
              alignment: Alignment.center,
              child: estComplete
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: AppTypography.bodySmall.copyWith(
                        color: estActif ? AppColors.white : AppColors.gray500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
EOF
echo "→ lib/shared/widgets/layout/progress_steps.dart créé."

echo ""
echo "============================================================"
echo "  ✔ Script 07 terminé avec succès."
echo "============================================================"
echo ""
echo "RÉCAPITULATIF DE CE QUI A ÉTÉ CRÉÉ :"
echo "  • Boutons : AppPrimaryButton, AppSecondaryButton, AppIconButton"
echo "  • Champs : AppTextField, AppSearchField"
echo "  • Cartes : ProductCard, StatusBadge, AppAvatar, InfoRow"
echo "  • Feedback : AppLoadingIndicator, AppSnackbar"
echo "  • 7 illustrations SVG vectorielles (confiance, vérification,"
echo "    paiement, succès, vide, localisation, messagerie)"
echo "  • Layout : AppScaffold, SectionHeader, ProgressSteps"
echo ""
echo "PROCHAINE ÉTAPE :"
echo "  Dites-moi quand vous êtes prêt pour le script 08 : les"
echo "  providers Riverpod (état global, session utilisateur,"
echo "  injection des repositories selon le mode local/API) — la"
echo "  dernière brique avant de commencer les écrans eux-mêmes."
echo ""

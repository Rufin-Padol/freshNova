import 'package:flutter/material.dart';

/// Palette de couleurs officielle AfriDeal.
///
/// Ces couleurs sont la SEULE source de vérité pour les couleurs de
/// l'application. Aucun écran ne doit écrire une couleur en dur
/// (ex: Color(0xFF7C3AED)) : il doit toujours passer par AppColors.
///
/// La palette respecte l'identité de marque validée :
/// Violet + Bleu + Blanc + Noir + Or = confiance, sécurité et modernité.
class AppColors {
  AppColors._();

  // ── Couleurs de marque ──
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetDark = Color(0xFF5B21B6);
  static const Color violetLight = Color(0xFF8B5CF6);
  static const Color violetSurface = Color(0xFFEDE9FE);

  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1D4ED8);
  static const Color blueSurface = Color(0xFFEFF6FF);

  static const Color gold = Color(0xFFF59E0B);
  static const Color goldDark = Color(0xFFB45309);
  static const Color goldSurface = Color(0xFFFEF3C7);

  static const Color black = Color(0xFF111827);
  static const Color white = Color(0xFFFFFFFF);

  // ── Neutres (échelle de gris) ──
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ── Couleurs sémantiques (états) ──
  static const Color success = Color(0xFF059669);
  static const Color successSurface = Color(0xFFD1FAE5);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSurface = Color(0xFFFEE2E2);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // ── Couleurs de fond ──
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Statuts produit (cycle de vie, voir ProductStatus) ──
  static const Color statusSubmitted = gold;
  static const Color statusAssigned = blue;
  static const Color statusVerifying = violet;
  static const Color statusCollected = Color(0xFF0D9488);
  static const Color statusProcessing = Color(0xFF0D9488);
  static const Color statusOnSale = success;
  static const Color statusReserved = violetDark;
  static const Color statusDelivered = Color(0xFF166534);
  static const Color statusRefused = danger;
  static const Color statusCancelled = gray500;
  static const Color statusUnavailable = danger;
  static const Color statusExpired = gray400;

  /// Dégradé principal de marque, utilisé sur les écrans d'accueil,
  /// bannières, et boutons d'action principaux.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, blue],
  );

  /// Dégradé sombre, utilisé pour les bandeaux de confiance / sécurité.
  static const LinearGradient darkTrustGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [black, violetDark],
  );
}

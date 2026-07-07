import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Construit le ThemeData complet consommé par MaterialApp.router.
///
/// Centraliser ici le style de chaque composant (boutons, champs de
/// texte, app bar...) garantit que les widgets Material par défaut
/// (TextButton, ElevatedButton, etc.) respectent automatiquement
/// l'identité visuelle AfriDeal sans configuration répétée écran par écran.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violet,
        primary: AppColors.violet,
        secondary: AppColors.blue,
        tertiary: AppColors.gold,
        error: AppColors.danger,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.black,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.titleLarge,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray400,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violet,
          side: const BorderSide(color: AppColors.violet, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.violet,
          textStyle: AppTypography.button,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.gray400),
        labelStyle: AppTypography.bodyMedium,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
          side: const BorderSide(color: AppColors.gray200),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.violet,
        unselectedItemColor: AppColors.gray400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: AppTypography.caption,
        unselectedLabelStyle: AppTypography.caption,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray900,
        contentTextStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        labelStyle: AppTypography.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
        side: BorderSide.none,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.violet,
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

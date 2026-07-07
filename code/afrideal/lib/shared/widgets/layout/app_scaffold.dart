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

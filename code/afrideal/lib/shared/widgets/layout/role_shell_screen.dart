import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/session_provider.dart';
import 'app_bottom_nav.dart';

/// Écran coquille qui injecte la barre de navigation inférieure
/// appropriée selon le rôle de l'utilisateur, autour de n'importe
/// quel écran contenu.
///
/// En encapsulant les écrans principaux dans ce shell, on évite que
/// chaque écran ait à déclarer lui-même sa BottomNavigationBar —
/// ce qui éliminerait l'animation fluide de transition et causerait
/// un "clignotement" de la barre lors de chaque navigation.
class RoleShellScreen extends ConsumerWidget {
  final Widget child;

  const RoleShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(currentUserProvider);
    if (utilisateur == null) return child;

    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        role: utilisateur.role,
        currentRoute: currentRoute,
      ),
    );
  }
}

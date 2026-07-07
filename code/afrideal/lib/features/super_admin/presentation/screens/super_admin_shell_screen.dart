import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../widgets/super_admin_sidebar.dart';

/// Écran coquille du panel Super Admin — même schéma que
/// AdminShellScreen (sidebar fixe sur le web, drawer sur mobile).
class SuperAdminShellScreen extends StatelessWidget {
  final Widget child;
  const SuperAdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width > 800;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SuperAdminSidebar(currentRoute: currentRoute),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Administration'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(child: SuperAdminSidebar(currentRoute: currentRoute)),
      body: child,
    );
  }
}

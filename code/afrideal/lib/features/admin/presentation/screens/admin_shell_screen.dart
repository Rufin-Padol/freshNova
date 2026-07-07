import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../widgets/admin_sidebar.dart';

/// Écran coquille du panel Admin.
///
/// Sur le web (ou écran large), affiche une sidebar fixe à gauche et
/// le contenu à droite. Sur mobile, la sidebar devient un Drawer
/// accessible via le bouton menu de l'AppBar — la même codebase
/// fonctionne sur les deux contextes sans duplication.
class AdminShellScreen extends StatelessWidget {
  final Widget child;
  const AdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width > 800;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AdminSidebar(currentRoute: currentRoute),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(child: AdminSidebar(currentRoute: currentRoute)),
      body: child,
    );
  }
}

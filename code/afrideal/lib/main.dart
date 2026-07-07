import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'data/local/datasources/hive_service.dart';
import 'data/local/seed/demo_data_seeder.dart';

Future<void> main() async {
  // Garantit que les bindings Flutter sont initialisés avant tout
  // appel à du code natif (Hive, plugins...), requis car main() est
  // maintenant asynchrone (à cause de l'initialisation Hive ci-dessous).
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise les données de locale française (dates, montants) —
  // requis par tous les usages de Formatters/intl dans l'application,
  // sans quoi tout écran affichant une date plante au premier appel.
  await initializeDateFormatting('fr_FR');

  // Initialise la base de données locale et ouvre toutes les box
  // nécessaires au fonctionnement de l'application.
  await HiveService.init();

  // Insère les données de démonstration au tout premier lancement
  // uniquement. Sans effet aux lancements suivants. N'a de sens qu'en
  // mode local : en mode API, les données viendraient du serveur.
  if (AppConfig.isLocal) {
    await DemoDataSeeder.seedIfNeeded();
  }

  runApp(const ProviderScope(child: AfriDealApp()));
}

/// Widget racine de l'application AfriDeal.
///
/// Utilise ConsumerWidget pour pouvoir lire le routeur depuis
/// Riverpod (lui-même réactif à l'état de session, voir
/// lib/core/router/app_router.dart).
class AfriDealApp extends ConsumerWidget {
  const AfriDealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:afrideal/main.dart';

void main() {
  testWidgets('AfriDealApp démarre et affiche un écran', (WidgetTester tester) async {
    // Hive dépend de path_provider (canal de plateforme non simulé
    // dans l'environnement de test) : on ne l'initialise pas ici. Les
    // providers qui en dépendent (session, catalogue...) basculent
    // simplement en état d'erreur, ce qui suffit pour ce test de fumée.
    await tester.pumpWidget(const ProviderScope(child: AfriDealApp()));
    await tester.pump();

    expect(find.byType(AfriDealApp), findsOneWidget);
  });
}

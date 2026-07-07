import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:afrideal/data/local/datasources/hive_service.dart';
import 'package:afrideal/main.dart';

void main() {
  testWidgets('AfriDealApp démarre et affiche un écran', (WidgetTester tester) async {
    await HiveService.init();

    await tester.pumpWidget(const ProviderScope(child: AfriDealApp()));
    await tester.pump();

    expect(find.byType(AfriDealApp), findsOneWidget);
  });
}

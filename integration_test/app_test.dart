import 'package:certificat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/fake_repositories.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign-in opens the dashboard and all five app sections',
      (tester) async {
    await tester.pumpWidget(
      PulseboardApp(
        auth: FakeAuthRepository(),
        catalog: FakeCatalogRepository(userRecords: const []),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Un aperçu rapide de votre espace Pulseboard.'), findsOneWidget);
    await tester.tap(find.text('Utilisateurs').last);
    await tester.pumpAndSettle();
    expect(find.text('Aucun élément pour le moment.'), findsOneWidget);
    await tester.tap(find.text('Articles').last);
    await tester.pumpAndSettle();
    expect(find.text('Building with Flutter'), findsOneWidget);
    await tester.tap(find.text('Tâches').last);
    await tester.pumpAndSettle();
    expect(find.text('Review accessibility'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Accessibilité'), findsOneWidget);
  });

  testWidgets('changing locale in settings updates navigation and content',
      (tester) async {
    await tester.pumpWidget(
      PulseboardApp(
        auth: FakeAuthRepository(authenticated: true),
        catalog: FakeCatalogRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('App language'), findsOneWidget);
    expect(find.text('Accessibility'), findsOneWidget);
  });
}

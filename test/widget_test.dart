import 'package:certificat/main.dart';
import 'package:certificat/presentation/certification_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_repositories.dart';

Widget buildApp({
  FakeAuthRepository? auth,
  FakeCatalogRepository? catalog,
}) {
  return PulseboardApp(
    auth: auth ?? FakeAuthRepository(),
    catalog: catalog ?? FakeCatalogRepository(),
  );
}

void main() {
  testWidgets('login form exposes labelled fields and a sign-in action',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Identifiant'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byTooltip('Changer de langue'), findsOneWidget);
  });

  testWidgets('login controls expose accessible semantic labels',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();

    expect(find.bySemanticsLabel('Identifiant'), findsOneWidget);
    expect(find.bySemanticsLabel('Mot de passe'), findsOneWidget);
    expect(find.bySemanticsLabel('Se connecter'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('empty credentials show validation errors without signing in',
      (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(buildApp(auth: auth));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Utilisez au moins 3 caractères.'), findsOneWidget);
    expect(find.text('Utilisez au moins 8 caractères.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(auth.isAuthenticated, isFalse);
  });

  testWidgets('login language control switches visible copy to English',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Changer de langue'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('registration action reveals all registration fields',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un nouveau compte'));
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte.'), findsOneWidget);
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('successful sign-in shows five labelled navigation destinations',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    for (final label in [
      'Vue d’ensemble',
      'Utilisateurs',
      'Articles',
      'Tâches',
      'Réglages',
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) => widget is NavigationDestination && widget.label == label,
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('settings language selector localizes the production notes',
      (tester) async {
    await tester.pumpWidget(
      buildApp(auth: FakeAuthRepository(authenticated: true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('App language'), findsOneWidget);
    expect(find.text('Built for production'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == 'Settings',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sign-out returns to the login form', (tester) async {
    final auth = FakeAuthRepository(authenticated: true);
    await tester.pumpWidget(buildApp(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(auth.isAuthenticated, isFalse);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}

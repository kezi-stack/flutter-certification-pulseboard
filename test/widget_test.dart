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
    expect(find.text('Vue d’ensemble'), findsWidgets);
    expect(find.text('Utilisateurs'), findsOneWidget);
    expect(find.text('Articles'), findsOneWidget);
    expect(find.text('Tâches'), findsOneWidget);
    expect(find.text('Réglages'), findsOneWidget);
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
    expect(find.text('Settings'), findsOneWidget);
  });
}

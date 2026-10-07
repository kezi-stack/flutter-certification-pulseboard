import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_strings.dart';
import 'data/api_client.dart';
import 'data/local_store.dart';
import 'data/repositories.dart';
import 'domain/repositories.dart';
import 'presentation/certification_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final authBox = await Hive.openBox<String>('auth');
  final cacheBox = await Hive.openBox<String>('cache');
  final store = LocalStore(authBox, cacheBox);
  final api = ApiClient(store);
  final auth = AuthRepository(api, store);
  final catalog = CatalogRepository(api, store);

  runApp(PulseboardApp(auth: auth, catalog: catalog));
}

class PulseboardApp extends StatefulWidget {
  const PulseboardApp({
    super.key,
    required this.auth,
    required this.catalog,
  });

  final AuthRepositoryContract auth;
  final CatalogRepositoryContract catalog;

  @override
  State<PulseboardApp> createState() => _PulseboardAppState();
}

class _PulseboardAppState extends State<PulseboardApp> {
  Locale _locale = const Locale('fr');

  void _changeLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pulseboard',
      locale: _locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffe86a33)),
        scaffoldBackgroundColor: const Color(0xfff7f4ef),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: widget.auth.isAuthenticated
          ? HomePage(
              auth: widget.auth,
              catalog: widget.catalog,
              onLocaleChanged: _changeLocale,
            )
          : LoginPage(
              auth: widget.auth,
              catalog: widget.catalog,
              onLocaleChanged: _changeLocale,
            ),
    );
  }
}

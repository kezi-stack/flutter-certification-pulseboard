import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/api_client.dart';
import 'data/local_store.dart';
import 'data/repositories.dart';
import 'presentation/pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final authBox = await Hive.openBox<String>('auth');
  final cacheBox = await Hive.openBox<String>('cache');

  final store = LocalStore(authBox, cacheBox);
  final api = ApiClient(store);
  final auth = AuthRepository(api, store);

  runApp(PulseboardApp(auth: auth));
}

class PulseboardApp extends StatelessWidget {
  const PulseboardApp({super.key, required this.auth});

  final AuthRepository auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pulseboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffe86a33),
        ),
        scaffoldBackgroundColor: const Color(0xfff7f4ef),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: auth.isAuthenticated
          ? HomePage(auth: auth)
          : LoginPage(auth: auth),
    );
  }
}

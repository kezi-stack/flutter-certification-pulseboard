import 'package:flutter/material.dart';

import '../core/app_failure.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.auth,
    required this.catalog,
  });

  final AuthRepositoryContract auth;
  final CatalogRepositoryContract catalog;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController(text: 'admin');
  final password = TextEditingController(text: 'Password@123');
  final name = TextEditingController();
  final email = TextEditingController();

  bool registering = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    name.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (registering &&
        (name.text.trim().isEmpty ||
            email.text.trim().isEmpty ||
            username.text.trim().isEmpty ||
            password.text.isEmpty)) {
      setState(() => error = 'Tous les champs sont obligatoires.');
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      if (registering) {
        await widget.auth.register(
          name: name.text,
          username: username.text,
          email: email.text,
          password: password.text,
        );
      } else {
        await widget.auth.login(username.text, password.text);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            auth: widget.auth,
            catalog: widget.catalog,
          ),
        ),
      );
    } on AppFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, size: 52),
                const SizedBox(height: 24),
                Text(
                  registering ? 'Créer un compte.' : 'Bienvenue.',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pulseboard — JWT, REST, cache Hive et fonctionnement hors connexion.',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 28),
                if (error != null) _Notice(text: error!),
                if (registering)
                  _field(name, 'Nom complet'),
                if (registering)
                  _field(email, 'Email', keyboardType: TextInputType.emailAddress),
                _field(username, 'Identifiant'),
                _field(password, 'Mot de passe', obscureText: true),
                if (!registering)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Compte de démonstration : admin / Password@123',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                if (registering)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Le compte est créé par l’API puis la session JWT est ouverte automatiquement.',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: busy ? null : submit,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(registering ? 'Créer le compte' : 'Se connecter'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                              registering = !registering;
                              error = null;
                            }),
                    child: Text(
                      registering
                          ? 'J’ai déjà un compte'
                          : 'Créer un nouveau compte',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.auth,
    required this.catalog,
  });

  final AuthRepositoryContract auth;
  final CatalogRepositoryContract catalog;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  Future<void> logout() async {
    await widget.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          auth: widget.auth,
          catalog: widget.catalog,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Utilisateurs', 'Articles', 'Tâches'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (widget.auth.currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: Text(
                  widget.auth.currentUser!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: [
          UsersPage(repository: widget.catalog),
          PostsPage(repository: widget.catalog),
          TodosPage(repository: widget.catalog),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Utilisateurs',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_rounded),
            label: 'Articles',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: 'Tâches',
          ),
        ],
      ),
    );
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.repository});

  final CatalogRepositoryContract repository;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with AutomaticKeepAliveClientMixin {
  late Future<DataResult<List<User>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.users();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DataSection<User>(
      future: future,
      title: 'Utilisateurs',
      subtitle: 'GET /users — données REST du backend public.',
      itemBuilder: (item) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Text(item.name.isEmpty ? '?' : item.name[0])),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${item.username} • ${item.email}'),
        ),
      ),
      onRetry: () => setState(() => future = widget.repository.users()),
    );
  }
}

class PostsPage extends StatefulWidget {
  const PostsPage({super.key, required this.repository});

  final CatalogRepositoryContract repository;

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage>
    with AutomaticKeepAliveClientMixin {
  late Future<DataResult<List<Post>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.posts();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DataSection<Post>(
      future: future,
      title: 'Articles',
      subtitle: 'GET /posts — publications REST.',
      itemBuilder: (item) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 8),
              Text(item.body, maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
      onRetry: () => setState(() => future = widget.repository.posts()),
    );
  }
}

class TodosPage extends StatefulWidget {
  const TodosPage({super.key, required this.repository});

  final CatalogRepositoryContract repository;

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage>
    with AutomaticKeepAliveClientMixin {
  late Future<DataResult<List<Todo>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.todos();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DataSection<Todo>(
      future: future,
      title: 'Tâches',
      subtitle: 'GET /todos — état de progression.',
      itemBuilder: (item) => Card(
        child: ListTile(
          leading: Icon(
            item.completed ? Icons.check_circle : Icons.radio_button_unchecked,
          ),
          title: Text(item.title),
          subtitle: Text('Utilisateur ${item.userId}'),
          trailing: Text(item.completed ? 'Terminée' : 'À faire'),
        ),
      ),
      onRetry: () => setState(() => future = widget.repository.todos()),
    );
  }
}

class DataSection<T> extends StatelessWidget {
  const DataSection({
    super.key,
    required this.future,
    required this.title,
    required this.subtitle,
    required this.itemBuilder,
    required this.onRetry,
  });

  final Future<DataResult<List<T>>> future;
  final String title;
  final String subtitle;
  final Widget Function(T) itemBuilder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataResult<List<T>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message = snapshot.error is AppFailure
              ? (snapshot.error! as AppFailure).message
              : 'Une erreur inattendue est survenue.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Notice(text: message),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final result = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (result.fromCache)
                        const Chip(
                          avatar: Icon(Icons.cloud_off, size: 16),
                          label: Text('Hors ligne'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => onRetry(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: result.data.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => itemBuilder(result.data[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xffffe6df),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

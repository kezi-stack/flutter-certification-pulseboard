import 'package:flutter/material.dart';

import '../core/app_failure.dart';
import '../data/repositories.dart';
import '../domain/models.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController(text: 'emilys');
  final password = TextEditingController(text: 'emilyspass');
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();

  bool registering = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (registering &&
        (firstName.text.trim().isEmpty ||
            lastName.text.trim().isEmpty ||
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
          firstName: firstName.text,
          lastName: lastName.text,
          email: email.text,
          username: username.text,
          password: password.text,
        );
        if (!mounted) return;
        setState(() {
          registering = false;
          error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profil créé. Connecte-toi avec un compte disponible dans DummyJSON.',
            ),
          ),
        );
      } else {
        await widget.auth.login(username.text, password.text);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(auth: widget.auth)),
        );
      }
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
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, size: 52),
                const SizedBox(height: 24),
                Text(
                  registering ? 'Créer un espace.' : 'Bon retour.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pulseboard — API REST, JWT et données disponibles hors connexion.',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 28),
                if (error != null) _Notice(text: error!),
                if (registering) ...[
                  _field(firstName, 'Prénom'),
                  _field(lastName, 'Nom'),
                  _field(email, 'Email', keyboardType: TextInputType.emailAddress),
                ],
                _field(username, 'Identifiant'),
                _field(password, 'Mot de passe', obscureText: true),
                if (!registering)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Compte de démonstration : emilys / emilyspass',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                if (registering)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'DummyJSON simule la création du compte : les utilisateurs ajoutés ne sont pas persistés par son serveur.',
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
                        : Text(
                            registering ? 'Créer le profil' : 'Se connecter',
                          ),
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
                          : 'Créer un profil',
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
  const HomePage({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  late final CatalogRepository catalog;

  @override
  void initState() {
    super.initState();
    catalog = CatalogRepository(widget.auth.api, widget.auth.store);
  }

  Future<void> logout() async {
    await widget.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage(auth: widget.auth)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Produits', 'Articles', 'Équipe'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
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
          ProductsPage(repository: catalog),
          ArticlesPage(repository: catalog),
          PeoplePage(repository: catalog),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_rounded),
            label: 'Articles',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Équipe',
          ),
        ],
      ),
    );
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.repository});

  final CatalogRepository repository;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Product>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.products();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AsyncSection<Product>(
      future: future,
      title: 'Catalogue',
      subtitle: 'Première source REST : produits DummyJSON.',
      builder: (items) => GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisExtent: 225,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => ProductCard(item: items[i]),
      ),
      onRetry: () => setState(() => future = widget.repository.products()),
    );
  }
}

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key, required this.repository});

  final CatalogRepository repository;

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Article>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.articles();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AsyncSection<Article>(
      future: future,
      title: 'Articles',
      subtitle: 'Deuxième source REST : publications DummyJSON.',
      builder: (items) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${item.tags.join(' • ')}  |  ${item.views} vues',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      onRetry: () => setState(() => future = widget.repository.articles()),
    );
  }
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key, required this.repository});

  final CatalogRepository repository;

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Person>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.people();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AsyncSection<Person>(
      future: future,
      title: 'Équipe',
      subtitle: 'Troisième source REST : utilisateurs DummyJSON.',
      builder: (items) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    item.image.isNotEmpty ? NetworkImage(item.image) : null,
                child: item.image.isEmpty
                    ? Text(item.name.isEmpty ? '?' : item.name[0])
                    : null,
              ),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item.email),
            ),
          );
        },
      ),
      onRetry: () => setState(() => future = widget.repository.people()),
    );
  }
}

class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.future,
    required this.title,
    required this.subtitle,
    required this.builder,
    required this.onRetry,
  });

  final Future<List<T>> future;
  final String title;
  final String subtitle;
  final Widget Function(List<T>) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Expanded(child: builder(snapshot.data ?? const [])),
          ],
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.item});

  final Product item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              item.thumbnail,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xffeee8df),
                child: Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              '${item.price.toStringAsFixed(2)} USD • ${item.rating.toStringAsFixed(1)}/5',
            ),
          ),
        ],
      ),
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

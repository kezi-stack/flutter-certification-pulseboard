import 'package:flutter/material.dart';

import '../core/app_failure.dart';
import '../core/app_strings.dart';
import '../domain/form_validation.dart';
import '../domain/models.dart';
import '../domain/pulseboard_stats.dart';
import '../domain/repositories.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.auth,
    required this.catalog,
    required this.onLocaleChanged,
  });

  final AuthRepositoryContract auth;
  final CatalogRepositoryContract catalog;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController(text: 'admin');
  final _password = TextEditingController(text: 'Password@123');
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit(AppStrings strings) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_registering) {
        await widget.auth.register(
          name: _name.text.trim(),
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await widget.auth.login(_username.text.trim(), _password.text);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomePage(
            auth: widget.auth,
            catalog: widget.catalog,
            onLocaleChanged: widget.onLocaleChanged,
          ),
        ),
      );
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } on Object {
      if (mounted) setState(() => _error = strings.unexpectedError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _messageFor(String? key, AppStrings strings) => switch (key) {
        'nameTooShort' => strings.nameTooShort,
        'usernameTooShort' => strings.usernameTooShort,
        'passwordTooShort' => strings.passwordTooShort,
        'invalidEmail' => strings.invalidEmail,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: strings.changeLanguage,
            onPressed: () => widget.onLocaleChanged(
              Locale(strings.isEnglish ? 'fr' : 'en'),
            ),
            icon: const Icon(Icons.translate_rounded),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt_rounded, size: 52),
                  const SizedBox(height: 24),
                  Text(
                    _registering ? strings.createAccount : strings.welcome,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.loginSubtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  if (_error != null) _Notice(text: _error!),
                  if (_registering)
                    _field(
                      controller: _name,
                      label: strings.fullName,
                      validator: (value) =>
                          _messageFor(validateName(value ?? ''), strings),
                      textInputAction: TextInputAction.next,
                    ),
                  if (_registering)
                    _field(
                      controller: _email,
                      label: strings.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          _messageFor(validateEmail(value ?? ''), strings),
                      textInputAction: TextInputAction.next,
                    ),
                  _field(
                    controller: _username,
                    label: strings.username,
                    validator: (value) =>
                        _messageFor(validateUsername(value ?? ''), strings),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                  ),
                  _field(
                    controller: _password,
                    label: strings.password,
                    obscureText: true,
                    validator: (value) =>
                        _messageFor(validatePassword(value ?? ''), strings),
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(strings),
                  ),
                  if (!_registering)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        strings.demoAccount,
                        style: const TextStyle(color: Colors.black45),
                      ),
                    ),
                  if (_registering)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        strings.registrationNote,
                        style: const TextStyle(color: Colors.black45),
                      ),
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _busy ? null : () => _submit(strings),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_registering ? strings.register : strings.login),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _registering = !_registering;
                                _error = null;
                              }),
                      child: Text(
                        _registering ? strings.haveAccount : strings.needAccount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    bool obscureText = false,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
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
    required this.onLocaleChanged,
  });

  final AuthRepositoryContract auth;
  final CatalogRepositoryContract catalog;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  Future<void> _logout() async {
    await widget.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(
          auth: widget.auth,
          catalog: widget.catalog,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final pages = <Widget>[
      DashboardPage(catalog: widget.catalog),
      UsersPage(repository: widget.catalog),
      PostsPage(repository: widget.catalog),
      TodosPage(repository: widget.catalog),
      SettingsPage(
        locale: Localizations.localeOf(context),
        onLocaleChanged: widget.onLocaleChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.tabTitle(_index),
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
            tooltip: strings.changeLanguage,
            onPressed: () => widget.onLocaleChanged(
              Locale(strings.isEnglish ? 'fr' : 'en'),
            ),
            icon: const Icon(Icons.translate_rounded),
          ),
          IconButton(
            tooltip: strings.signOut,
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.space_dashboard_rounded),
            label: strings.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_alt_rounded),
            label: strings.users,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_rounded),
            label: strings.posts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: strings.tasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: strings.settings,
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.catalog});

  final CatalogRepositoryContract catalog;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  late Future<PulseboardStats> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  Future<PulseboardStats> _loadStats() async {
    final users = await widget.catalog.users();
    final posts = await widget.catalog.posts();
    final todos = await widget.catalog.todos();
    return PulseboardStats.fromData(
      users: users.data,
      posts: posts.data,
      todos: todos.data,
    );
  }

  Future<void> _refresh() async {
    setState(() => _stats = _loadStats());
    await _stats;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = AppStrings.of(context);
    return FutureBuilder<PulseboardStats>(
      future: _stats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _FailureView(
            message: snapshot.error is AppFailure
                ? (snapshot.error! as AppFailure).message
                : strings.unexpectedError,
            onRetry: _refresh,
          );
        }

        final stats = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                strings.dashboardSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    label: strings.peopleTracked,
                    value: '${stats.userCount}',
                    icon: Icons.people_alt_rounded,
                  ),
                  _MetricCard(
                    label: strings.publishedPosts,
                    value: '${stats.postCount}',
                    icon: Icons.auto_stories_rounded,
                  ),
                  _MetricCard(
                    label: strings.completed,
                    value: '${stats.completedTaskCount}/${stats.taskCount}',
                    icon: Icons.task_alt_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.taskProgress,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: strings.taskProgress,
                        value: '${stats.completionPercentage}%',
                        child: LinearProgressIndicator(
                          value: stats.completionPercentage / 100,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${stats.completionPercentage}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.offline_bolt_rounded),
                  title: Text(strings.activity),
                  subtitle: Text(strings.architectureDescription),
                ),
              ),
            ],
          ),
        );
      },
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
  late Future<DataResult<List<User>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.users();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.repository.users());
    await _future;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = AppStrings.of(context);
    return DataListSection<User>(
      future: _future,
      title: strings.users,
      subtitle: strings.usersSubtitle,
      onRetry: _refresh,
      itemBuilder: (user) => Card(
        child: ListTile(
          leading: _OptimizedAvatar(user: user),
          title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${user.username} • ${user.email}'),
        ),
      ),
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
  late Future<DataResult<List<Post>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.posts();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.repository.posts());
    await _future;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = AppStrings.of(context);
    return DataListSection<Post>(
      future: _future,
      title: strings.posts,
      subtitle: strings.postsSubtitle,
      onRetry: _refresh,
      itemBuilder: (post) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text(post.body, maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
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
  late Future<DataResult<List<Todo>>> _future;
  bool? _completedFilter;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.todos();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.repository.todos());
    await _future;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = AppStrings.of(context);
    return DataListSection<Todo>(
      future: _future,
      title: strings.tasks,
      subtitle: strings.tasksSubtitle,
      onRetry: _refresh,
      transformItems: (items) =>
          filterTodos(items, completed: _completedFilter),
      headerTrailing: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(strings.allTasks),
            selected: _completedFilter == null,
            onSelected: (_) => setState(() => _completedFilter = null),
          ),
          ChoiceChip(
            label: Text(strings.openTasks),
            selected: _completedFilter == false,
            onSelected: (_) => setState(() => _completedFilter = false),
          ),
          ChoiceChip(
            label: Text(strings.completedTasks),
            selected: _completedFilter == true,
            onSelected: (_) => setState(() => _completedFilter = true),
          ),
        ],
      ),
      itemBuilder: (todo) => Card(
        child: ListTile(
          leading: Icon(
            todo.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
          ),
          title: Text(todo.title),
          subtitle: Text('${strings.userLabel} ${todo.userId}'),
          trailing: Text(todo.completed ? strings.taskDone : strings.taskToDo),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          strings.languageSection,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Semantics(
          label: strings.languageSection,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'fr',
                label: Text('Français'),
                icon: Icon(Icons.language_rounded),
              ),
              ButtonSegment<String>(
                value: 'en',
                label: Text('English'),
                icon: Icon(Icons.language_rounded),
              ),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (selection) =>
                onLocaleChanged(Locale(selection.first)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          strings.accessibilitySection,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.accessibility_new_rounded),
            title: Text(strings.accessibilityDescription),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          strings.architectureSection,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(strings.architectureDescription),
            subtitle: Text(strings.versionLabel),
          ),
        ),
      ],
    );
  }
}

class DataListSection<T> extends StatelessWidget {
  const DataListSection({
    super.key,
    required this.future,
    required this.title,
    required this.subtitle,
    required this.itemBuilder,
    required this.onRetry,
    this.transformItems,
    this.headerTrailing,
  });

  final Future<DataResult<List<T>>> future;
  final String title;
  final String subtitle;
  final Widget Function(T) itemBuilder;
  final Future<void> Function() onRetry;
  final List<T> Function(List<T>)? transformItems;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return FutureBuilder<DataResult<List<T>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _FailureView(
            message: snapshot.error is AppFailure
                ? (snapshot.error! as AppFailure).message
                : strings.unexpectedError,
            onRetry: onRetry,
          );
        }

        final result = snapshot.data!;
        final items = transformItems?.call(result.data) ?? result.data;
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
                        Chip(
                          avatar: const Icon(Icons.cloud_off_rounded, size: 16),
                          label: Text(strings.offline),
                        ),
                    ],
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                  if (headerTrailing != null) ...[
                    const SizedBox(height: 12),
                    headerTrailing!,
                  ],
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRetry,
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(child: Text(strings.noData)),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            itemBuilder(items[index]),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptimizedAvatar extends StatelessWidget {
  const _OptimizedAvatar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final avatarId = (int.tryParse(user.id) ?? 0) % 70 + 1;
    return Semantics(
      image: true,
      label: '${strings.userLabel}: ${user.name}',
      child: ClipOval(
        child: Image.network(
          'https://i.pravatar.cc/128?img=$avatarId',
          width: 48,
          height: 48,
          cacheWidth: 96,
          cacheHeight: 96,
          filterQuality: FilterQuality.low,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
              frame != null || wasSynchronouslyLoaded
                  ? child
                  : const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
          errorBuilder: (context, error, stackTrace) => CircleAvatar(
            child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
          ),
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Notice(text: message),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(strings.retry),
            ),
          ],
        ),
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
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

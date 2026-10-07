import 'package:certificat/domain/models.dart';
import 'package:certificat/domain/repositories.dart';

class FakeAuthRepository implements AuthRepositoryContract {
  FakeAuthRepository({this.authenticated = false});

  bool authenticated;
  String? userName = 'Kezia';

  @override
  bool get isAuthenticated => authenticated;

  @override
  String? get currentUser => authenticated ? userName : null;

  @override
  Future<void> login(String username, String password) async {
    authenticated = true;
  }

  @override
  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    authenticated = true;
    userName = name;
  }

  @override
  Future<void> logout() async {
    authenticated = false;
  }
}

class FakeCatalogRepository implements CatalogRepositoryContract {
  FakeCatalogRepository({this.userRecords = const [demoUser]});

  static const demoUser = User(
    id: '1',
    name: 'Ariane Martin',
    username: 'ariane',
    email: 'ariane@example.com',
  );
  static const demoPost = Post(
    id: '1',
    userId: '1',
    title: 'Building with Flutter',
    body: 'A small, responsive application with a tested data layer.',
  );
  static const demoTodos = [
    Todo(id: '1', userId: '1', title: 'Ship the dashboard', completed: true),
    Todo(id: '2', userId: '1', title: 'Review accessibility', completed: false),
  ];

  final List<User> userRecords;

  @override
  Future<DataResult<List<User>>> users() async => DataResult(
        data: userRecords,
        fromCache: false,
      );

  @override
  Future<DataResult<List<Post>>> posts() async => const DataResult(
        data: [demoPost],
        fromCache: false,
      );

  @override
  Future<DataResult<List<Todo>>> todos() async => const DataResult(
        data: demoTodos,
        fromCache: false,
      );
}

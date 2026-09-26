import 'models.dart';

abstract interface class AuthRepositoryContract {
  bool get isAuthenticated;
  String? get currentUser;

  Future<void> login(String username, String password);

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });

  Future<void> logout();
}

abstract interface class CatalogRepositoryContract {
  Future<DataResult<List<User>>> users();
  Future<DataResult<List<Post>>> posts();
  Future<DataResult<List<Todo>>> todos();
}

import 'models.dart';

abstract interface class AuthRepositoryContract {
  bool get isAuthenticated;
  String? get currentUser;

  Future<void> login(String username, String password);

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  });

  Future<void> logout();
}

abstract interface class CatalogRepositoryContract {
  Future<List<Product>> products();
  Future<List<Article>> articles();
  Future<List<Person>> people();
}

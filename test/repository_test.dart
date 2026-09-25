import 'package:certificat/core/app_failure.dart';
import 'package:certificat/data/api_client.dart';
import 'package:certificat/data/local_store.dart';
import 'package:certificat/data/repositories.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class FakeStore implements SessionStore {
  String? storedToken;
  String? storedRefresh;
  String? storedUser;
  final values = <String, String>{};

  @override
  String? get token => storedToken;

  @override
  String? get refreshToken => storedRefresh;

  @override
  String? get userName => storedUser;

  @override
  Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String userName,
  }) async {
    storedToken = token;
    storedRefresh = refreshToken;
    storedUser = userName;
  }

  @override
  Future<void> clearSession() async {
    storedToken = null;
    storedRefresh = null;
    storedUser = null;
  }

  @override
  Future<void> cache(String key, String value) async {
    values[key] = value;
  }

  @override
  String? readCache(String key) => values[key];
}

Response<Map<String, dynamic>> responseFor(
  String path,
  Map<String, dynamic> data,
) {
  return Response(
    requestOptions: RequestOptions(path: path),
    data: data,
  );
}

void main() {
  late MockDio dio;
  late FakeStore store;
  late CatalogRepository repository;

  setUp(() {
    dio = MockDio();
    store = FakeStore();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = CatalogRepository(ApiClient(store, client: dio), store);
  });

  test('repository fetches products from REST and caches them', () async {
    when(() => dio.get('/products?limit=12')).thenAnswer(
      (_) async => responseFor(
        '/products?limit=12',
        {
          'products': [
            {
              'id': 1,
              'title': 'Desk',
              'price': 49,
              'rating': 4.5,
              'thumbnail': 'image',
            },
          ],
        },
      ),
    );

    final products = await repository.products();

    expect(products.single.title, 'Desk');
    expect(store.readCache('products'), contains('Desk'));
    verify(() => dio.get('/products?limit=12')).called(1);
  });

  test('repository reads cached articles when network fails', () async {
    await store.cache(
      'articles',
      '{"posts":[{"id":2,"title":"Release","body":"Notes","tags":["news"],"views":120}]}',
    );
    when(() => dio.get('/posts?limit=12')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/posts?limit=12'),
        type: DioExceptionType.connectionError,
      ),
    );

    final articles = await repository.articles();

    expect(articles.single.title, 'Release');
    expect(articles.single.views, 120);
  });

  test('repository returns a clear offline failure without cache', () async {
    when(() => dio.get('/users?limit=12')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/users?limit=12'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(
      repository.people(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.message,
          'message',
          contains('Hors connexion'),
        ),
      ),
    );
  });

  test('auth repository stores JWT and refresh token after login', () async {
    final auth = AuthRepository(ApiClient(store, client: dio), store);

    when(() => dio.post(
          '/auth/login',
          data: any(named: 'data'),
        )).thenAnswer(
      (_) async => responseFor(
        '/auth/login',
        {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'firstName': 'Emily',
          'lastName': 'Johnson',
        },
      ),
    );

    await auth.login('emilys', 'emilyspass');

    expect(auth.isAuthenticated, isTrue);
    expect(store.token, 'access-token');
    expect(store.refreshToken, 'refresh-token');
    expect(auth.currentUser, 'Emily Johnson');
  });

  test('auth repository logout clears the local session', () async {
    final auth = AuthRepository(ApiClient(store, client: dio), store);
    await store.saveSession(
      token: 'access',
      refreshToken: 'refresh',
      userName: 'Emily Johnson',
    );

    await auth.logout();

    expect(auth.isAuthenticated, isFalse);
    expect(auth.currentUser, isNull);
  });
}

import 'package:certificat/core/app_failure.dart';
import 'package:certificat/data/api_client.dart';
import 'package:certificat/data/local_store.dart';
import 'package:certificat/data/repositories.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}
class MockRequestHandler extends Mock implements RequestInterceptorHandler {}
class MockErrorHandler extends Mock implements ErrorInterceptorHandler {}
class FakeResponse extends Fake implements Response<dynamic> {}

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
  Future<void> cache(String key, String value) async => values[key] = value;
  @override
  String? readCache(String key) => values[key];
}

Response<Map<String, dynamic>> responseFor(
  String path,
  Map<String, dynamic> data,
) => Response(requestOptions: RequestOptions(path: path), data: data);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeResponse());
  });
  late MockDio dio;
  late FakeStore store;
  late CatalogRepository repository;

  setUp(() {
    dio = MockDio();
    store = FakeStore();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = CatalogRepository(ApiClient(store, client: dio), store);
  });

  test('repository fetches users from REST and caches them', () async {
    when(() => dio.get('/users?limit=12')).thenAnswer(
      (_) async => responseFor('/users?limit=12', {
        'data': [
          {
            'id': 1,
            'name': 'Jane Doe',
            'username': 'jane',
            'email': 'jane@example.com',
          },
        ],
      }),
    );

    final result = await repository.users();

    expect(result.fromCache, isFalse);
    expect(result.data.single.name, 'Jane Doe');
    expect(store.readCache('users'), contains('Jane Doe'));
    verify(() => dio.get('/users?limit=12')).called(1);
  });

  test('repository reads cached posts when network fails', () async {
    await store.cache(
      'posts',
      '[{"id":2,"user_id":1,"title":"Release","body":"Notes"}]',
    );
    when(() => dio.get('/posts?limit=12')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/posts?limit=12'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.posts();

    expect(result.fromCache, isTrue);
    expect(result.data.single.title, 'Release');
  });

  test('repository returns a clear offline failure without cache', () async {
    when(() => dio.get('/todos?limit=12')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/todos?limit=12'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(
      repository.todos(),
      throwsA(isA<AppFailure>().having(
        (failure) => failure.message,
        'message',
        contains('Hors connexion'),
      )),
    );
  });

  test('auth repository stores access and refresh JWT after login', () async {
    final auth = AuthRepository(ApiClient(store, client: dio), store);
    when(() => dio.post('/auth/login', data: any(named: 'data'))).thenAnswer(
      (_) async => responseFor('/auth/login', {
        'access_token': 'access-token',
        'refresh_token': 'refresh-token',
        'user': {'name': 'Admin', 'username': 'admin'},
      }),
    );
    when(() => dio.get('/auth/me')).thenAnswer(
      (_) async => responseFor('/auth/me', {'id': 1, 'name': 'Admin'}),
    );

    await auth.login('admin', 'Password@123');

    expect(auth.isAuthenticated, isTrue);
    expect(store.token, 'access-token');
    expect(store.refreshToken, 'refresh-token');
    expect(auth.currentUser, 'Admin');
  });

  test('auth repository register creates a JWT session', () async {
    final auth = AuthRepository(ApiClient(store, client: dio), store);
    when(() => dio.post('/auth/register', data: any(named: 'data'))).thenAnswer(
      (_) async => responseFor('/auth/register', {
        'access_token': 'registered-access',
        'refresh_token': 'registered-refresh',
        'user': {'name': 'Alice', 'username': 'alice'},
      }),
    );
    when(() => dio.get('/auth/me')).thenAnswer(
      (_) async => responseFor('/auth/me', {'id': 'local-1', 'name': 'Alice'}),
    );

    await auth.register(
      name: 'Alice',
      username: 'alice',
      email: 'alice@example.com',
      password: 'Password@123',
    );

    expect(auth.isAuthenticated, isTrue);
    expect(store.token, 'registered-access');
    expect(store.refreshToken, 'registered-refresh');
  });

  test('logout clears the local session', () async {
    final auth = AuthRepository(ApiClient(store, client: dio), store);
    await store.saveSession(
      token: 'access',
      refreshToken: 'refresh',
      userName: 'Admin',
    );

    await auth.logout();

    expect(auth.isAuthenticated, isFalse);
    expect(auth.currentUser, isNull);
  });

  test('interceptor injects Bearer access token', () async {
    final requestHandler = MockRequestHandler();
    store.storedToken = 'abc123';
    final client = MockDio();
    when(() => client.interceptors).thenReturn(Interceptors());
    final interceptor = AuthInterceptor(store: store, dio: client);
    final options = RequestOptions(path: '/posts');

    interceptor.onRequest(options, requestHandler);

    expect(options.headers['Authorization'], 'Bearer abc123');
    verify(() => requestHandler.next(options)).called(1);
  });

  test('interceptor refreshes tokens after 401 and retries request', () async {
    final errorHandler = MockErrorHandler();
    store.storedToken = 'old-access';
    store.storedRefresh = 'old-refresh';
    store.storedUser = 'Admin';

    when(() => dio.post('/auth/refresh', data: any(named: 'data'))).thenAnswer(
      (_) async => responseFor('/auth/refresh', {
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
      }),
    );
    when(() => dio.request<dynamic>(
          '/posts',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          onSendProgress: any(named: 'onSendProgress'),
        )).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/posts'),
        data: {'data': []},
      ),
    );

    final interceptor = AuthInterceptor(store: store, dio: dio);
    final error = DioException(
      requestOptions: RequestOptions(path: '/posts', method: 'GET'),
      response: Response(
        requestOptions: RequestOptions(path: '/posts'),
        statusCode: 401,
      ),
    );

    await interceptor.onError(error, errorHandler);

    expect(store.token, 'new-access');
    expect(store.refreshToken, 'new-refresh');
    verify(() => errorHandler.resolve(any())).called(1);
  });
}

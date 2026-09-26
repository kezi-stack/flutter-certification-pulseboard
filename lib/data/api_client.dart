import 'package:dio/dio.dart';

import 'local_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.store, required this.dio});

  final SessionStore store;
  final Dio dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = store.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final refreshToken = store.refreshToken;
    final alreadyRetried = request.extra['authRetry'] == true;
    final isRefreshCall = request.path == '/auth/refresh';

    if (err.response?.statusCode != 401 ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        isRefreshCall ||
        alreadyRetried) {
      if (err.response?.statusCode == 401 && isRefreshCall) {
        await store.clearSession();
      }
      handler.next(err);
      return;
    }

    try {
      final response = await dio.post(
        '/auth/refresh',
        data: <String, dynamic>{
          'refreshToken': refreshToken,
          'token_ttl': 900,
        },
      );

      final newAccessToken = response.data['access_token'] as String?;
      final newRefreshToken = response.data['refresh_token'] as String?;

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        throw const FormatException('Réponse de rafraîchissement invalide.');
      }

      await store.saveSession(
        token: newAccessToken,
        refreshToken: newRefreshToken,
        userName: store.userName ?? 'Utilisateur',
      );

      final retryRequest = Options(
        method: request.method,
        headers: Map<String, dynamic>.from(request.headers),
        responseType: request.responseType,
        contentType: request.contentType,
        sendTimeout: request.sendTimeout,
        receiveTimeout: request.receiveTimeout,
        extra: <String, dynamic>{
          ...request.extra,
          'authRetry': true,
        },
      );
      retryRequest.headers?['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await dio.request<dynamic>(
        request.path,
        data: request.data,
        queryParameters: request.queryParameters,
        options: retryRequest,
        cancelToken: request.cancelToken,
        onReceiveProgress: request.onReceiveProgress,
        onSendProgress: request.onSendProgress,
      );

      handler.resolve(retryResponse);
    } on Object {
      await store.clearSession();
      handler.next(err);
    }
  }
}

class ApiClient {
  ApiClient(this.store, {Dio? client})
      : dio = client ??
            Dio(
              BaseOptions(
                baseUrl: 'https://playground.nileslabs.com/api/v1',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                sendTimeout: const Duration(seconds: 8),
                headers: const {'Content-Type': 'application/json'},
              ),
            ) {
    dio.interceptors.add(AuthInterceptor(store: store, dio: dio));
  }

  final SessionStore store;
  final Dio dio;
}

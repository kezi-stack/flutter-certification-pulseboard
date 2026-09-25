import 'package:dio/dio.dart';

import 'local_store.dart';

class ApiClient {
  ApiClient(this.store, {Dio? client})
      : dio = client ??
            Dio(
              BaseOptions(
                baseUrl: 'https://dummyjson.com',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                sendTimeout: const Duration(seconds: 8),
                headers: const {'Content-Type': 'application/json'},
              ),
            ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = store.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final refreshToken = store.refreshToken;
          final isRefreshCall = request.path == '/auth/refresh';

          if (error.response?.statusCode != 401 ||
              refreshToken == null ||
              refreshToken.isEmpty ||
              isRefreshCall) {
            if (error.response?.statusCode == 401 && isRefreshCall) {
              await store.clearSession();
            }
            handler.next(error);
            return;
          }

          try {
            final refreshed = await dio.post(
              '/auth/refresh',
              data: <String, dynamic>{
                'refreshToken': refreshToken,
                'expiresInMins': 30,
              },
            );

            final newAccessToken =
                refreshed.data['accessToken'] as String?;
            if (newAccessToken == null || newAccessToken.isEmpty) {
              throw const FormatException('Token de rafraîchissement invalide.');
            }

            await store.saveSession(
              token: newAccessToken,
              refreshToken:
                  refreshed.data['refreshToken'] as String? ?? refreshToken,
              userName: store.userName ?? 'Utilisateur',
            );

            request.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(request);
            handler.resolve(retryResponse);
          } on Object {
            await store.clearSession();
            handler.next(error);
          }
        },
      ),
    );
  }

  final Dio dio;
}

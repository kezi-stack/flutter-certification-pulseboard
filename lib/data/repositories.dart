import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/app_failure.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'api_client.dart';
import 'local_store.dart';

class AuthRepository implements AuthRepositoryContract {
  AuthRepository(this.api, this.store);

  final ApiClient api;
  final SessionStore store;

  @override
  bool get isAuthenticated => store.token != null && store.token!.isNotEmpty;

  @override
  String? get currentUser => store.userName;

  @override
  Future<void> login(String username, String password) async {
    try {
      final response = await api.dio.post(
        '/auth/login',
        data: <String, dynamic>{
          'username': username.trim(),
          'password': password,
          'expiresInMins': 30,
        },
      );

      final accessToken = response.data['accessToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw const AppFailure('Réponse d’authentification invalide.');
      }

      await store.saveSession(
        token: accessToken,
        refreshToken: response.data['refreshToken'] as String? ?? '',
        userName:
            '${response.data['firstName'] ?? ''} ${response.data['lastName'] ?? ''}'
                .trim(),
      );
    } on DioException catch (error) {
      throw AppFailure(_networkMessage(error, 'Connexion impossible.'));
    } on AppFailure {
      rethrow;
    } on Object {
      throw const AppFailure('Réponse d’authentification invalide.');
    }
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      await api.dio.post(
        '/users/add',
        data: <String, dynamic>{
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'username': username.trim(),
          'password': password,
        },
      );
    } on DioException catch (error) {
      throw AppFailure(_networkMessage(error, 'Inscription impossible.'));
    }
  }

  @override
  Future<void> logout() => store.clearSession();

  String _networkMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Connexion réseau indisponible. Vérifie Internet et réessaie.';
    }
    return fallback;
  }
}

class CatalogRepository implements CatalogRepositoryContract {
  CatalogRepository(this.api, this.store);

  final ApiClient api;
  final SessionStore store;

  @override
  Future<List<Product>> products() => _fetchList<Product>(
        cacheKey: 'products',
        path: '/products?limit=12',
        listKey: 'products',
        decoder: Product.fromJson,
      );

  @override
  Future<List<Article>> articles() => _fetchList<Article>(
        cacheKey: 'articles',
        path: '/posts?limit=12',
        listKey: 'posts',
        decoder: Article.fromJson,
      );

  @override
  Future<List<Person>> people() => _fetchList<Person>(
        cacheKey: 'people',
        path: '/users?limit=12',
        listKey: 'users',
        decoder: Person.fromJson,
      );

  Future<List<T>> _fetchList<T>({
    required String cacheKey,
    required String path,
    required String listKey,
    required T Function(Map<String, dynamic>) decoder,
  }) async {
    try {
      final response = await api.dio.get(path);
      final raw = Map<String, dynamic>.from(response.data as Map);
      final list = raw[listKey];

      if (list is! List) {
        throw const FormatException('Liste absente de la réponse.');
      }

      await store.cache(cacheKey, jsonEncode(raw));
      return list
          .map((item) => decoder(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (error) {
      final cached = store.readCache(cacheKey);
      if (cached != null) {
        return _decodeCached<T>(cached, listKey, decoder);
      }
      throw AppFailure(
        error.type == DioExceptionType.connectionError ||
                error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout
            ? 'Hors connexion : aucune donnée en cache pour cet écran.'
            : 'Impossible de charger les données. Réessaie dans un instant.',
      );
    } on AppFailure {
      rethrow;
    } on Object {
      final cached = store.readCache(cacheKey);
      if (cached != null) {
        return _decodeCached<T>(cached, listKey, decoder);
      }
      throw const AppFailure('Les données reçues sont invalides.');
    }
  }

  List<T> _decodeCached<T>(
    String cached,
    String listKey,
    T Function(Map<String, dynamic>) decoder,
  ) {
    try {
      final raw = Map<String, dynamic>.from(jsonDecode(cached) as Map);
      final list = raw[listKey];
      if (list is! List) {
        throw const FormatException();
      }
      return list
          .map((item) => decoder(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on Object {
      throw const AppFailure('Le cache local est corrompu. Recharge en ligne.');
    }
  }
}

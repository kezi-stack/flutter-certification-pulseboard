import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/app_failure.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'api_client.dart';
import 'dtos.dart';
import 'local_store.dart';

class AuthRepository implements AuthRepositoryContract {
  AuthRepository(this.api, this.store);

  final ApiClient api;
  final SessionStore store;

  @override
  bool get isAuthenticated => store.token?.isNotEmpty == true;

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
          'token_ttl': 900,
        },
      );
      await _saveAuthResponse(response.data);
      await _verifyAuthenticatedSession();
    } on DioException catch (error) {
      throw AppFailure(_messageFrom(error, 'Connexion impossible.'));
    } on AppFailure {
      rethrow;
    } on Object {
      throw const AppFailure('Réponse d’authentification invalide.');
    }
  }

  @override
  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await api.dio.post(
        '/auth/register',
        data: <String, dynamic>{
          'name': name.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'token_ttl': 900,
        },
      );
      await _saveAuthResponse(response.data);
      await _verifyAuthenticatedSession();
    } on DioException catch (error) {
      throw AppFailure(_messageFrom(error, 'Inscription impossible.'));
    } on AppFailure {
      rethrow;
    } on Object {
      throw const AppFailure('Réponse d’inscription invalide.');
    }
  }

  Future<void> _saveAuthResponse(dynamic data) async {
    if (data is! Map) {
      throw const AppFailure('Réponse d’authentification invalide.');
    }

    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    final user = data['user'];

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        user is! Map) {
      throw const AppFailure('Le serveur n’a pas retourné les tokens JWT attendus.');
    }

    final name = user['name'] as String? ?? user['username'] as String? ?? 'Utilisateur';
    await store.saveSession(
      token: accessToken,
      refreshToken: refreshToken,
      userName: name,
    );
  }

  Future<void> _verifyAuthenticatedSession() async {
    try {
      await api.dio.get('/auth/me');
    } on DioException catch (error) {
      await store.clearSession();
      throw AppFailure(_messageFrom(error, 'La session JWT n’a pas pu être vérifiée.'));
    }
  }

  @override
  Future<void> logout() => store.clearSession();

  String _messageFrom(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
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
  Future<DataResult<List<User>>> users() => _fetch<User>(
        cacheKey: 'users',
        path: '/users?limit=12',
        decoder: (json) => UserDto.fromJson(json).toDomain(),
      );

  @override
  Future<DataResult<List<Post>>> posts() => _fetch<Post>(
        cacheKey: 'posts',
        path: '/posts?limit=12',
        decoder: (json) => PostDto.fromJson(json).toDomain(),
      );

  @override
  Future<DataResult<List<Todo>>> todos() => _fetch<Todo>(
        cacheKey: 'todos',
        path: '/todos?limit=12',
        decoder: (json) => TodoDto.fromJson(json).toDomain(),
      );

  Future<DataResult<List<T>>> _fetch<T>({
    required String cacheKey,
    required String path,
    required T Function(Map<String, dynamic>) decoder,
  }) async {
    try {
      final response = await api.dio.get(path);
      final raw = Map<String, dynamic>.from(response.data as Map);
      final list = raw['data'];

      if (list is! List) {
        throw const FormatException('Champ data absent.');
      }

      final items = list
          .map((item) => decoder(Map<String, dynamic>.from(item as Map)))
          .toList();
      await store.cache(cacheKey, jsonEncode(list));
      return DataResult(data: items, fromCache: false);
    } on DioException catch (error) {
      final cached = store.readCache(cacheKey);
      if (cached != null) {
        return DataResult(data: _decodeCached(cached, decoder), fromCache: true);
      }
      throw AppFailure(_offlineOrNetworkMessage(error));
    } on AppFailure {
      rethrow;
    } on Object {
      final cached = store.readCache(cacheKey);
      if (cached != null) {
        return DataResult(data: _decodeCached(cached, decoder), fromCache: true);
      }
      throw const AppFailure('Les données reçues sont invalides.');
    }
  }

  List<T> _decodeCached<T>(
    String cached,
    T Function(Map<String, dynamic>) decoder,
  ) {
    try {
      final list = jsonDecode(cached);
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

  String _offlineOrNetworkMessage(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Hors connexion : aucune donnée en cache pour cet écran.';
    }
    return 'Impossible de charger les données. Réessaie dans un instant.';
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_entity.dart';
import 'auth_models.dart';
import 'auth_remote_datasource.dart';

const _cachedUserKey = 'cached_user';

class AuthRepository {
  AuthRepository(this._dataSource);
  final AuthRemoteDataSource _dataSource;

  Future<void> _cacheUser(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
  }

  Future<UserEntity?> _loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cachedUserKey);
    if (json == null) return null;
    try {
      return UserEntity.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserKey);
  }

  Future<UserEntity> login(LoginRequest request) async {
    final response = await _dataSource.login(request);
    await DioClient.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    final user = UserEntity.fromJson(response.user.toJson());
    await _cacheUser(user);
    return user;
  }

  Future<UserEntity> register(RegisterRequest request) async {
    final response = await _dataSource.register(request);
    await DioClient.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    final user = UserEntity.fromJson(response.user.toJson());
    await _cacheUser(user);
    return user;
  }

  /// Returns null when user is new and needs to select a role.
  Future<UserEntity?> googleSignIn(String firebaseIdToken, {String? role}) async {
    final response = await _dataSource.googleSignIn(firebaseIdToken, role: role);
    if (response == null) return null;
    await DioClient.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    final user = UserEntity.fromJson(response.user.toJson());
    await _cacheUser(user);
    return user;
  }

  Future<void> logout() async {
    final refreshToken = await DioClient.getRefreshToken();
    try {
      await _dataSource.logout(refreshToken: refreshToken);
    } catch (_) {}
    await DioClient.clearTokens();
    await _clearCachedUser();
  }

  Future<UserEntity?> getMe() async {
    final token = await DioClient.getAccessToken();
    if (token == null) return null;
    try {
      final user = await _dataSource.getMe();
      final entity = UserEntity.fromJson(user.toJson());
      await _cacheUser(entity);
      return entity;
    } on DioException catch (e) {
      // Server definitively rejected the session → clear cache and log out.
      if (e.response?.statusCode == 401) {
        await _clearCachedUser();
        return null;
      }
      // Transient error (network down, 5xx) → stay logged in with cached data.
      return _loadCachedUser();
    } catch (_) {
      return _loadCachedUser();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(AuthRemoteDataSource(ref.read(dioClientProvider)));
});

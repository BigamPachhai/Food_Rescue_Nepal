import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_entity.dart';
import 'auth_models.dart';
import 'auth_remote_datasource.dart';

class AuthRepository {
  AuthRepository(this._dataSource);
  final AuthRemoteDataSource _dataSource;

  Future<UserEntity> login(LoginRequest request) async {
    final response = await _dataSource.login(request);
    await DioClient.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return UserEntity.fromJson(response.user.toJson());
  }

  Future<UserEntity> register(RegisterRequest request) async {
    final response = await _dataSource.register(request);
    await DioClient.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return UserEntity.fromJson(response.user.toJson());
  }

  Future<void> logout() async {
    final refreshToken = await DioClient.getRefreshToken();
    try {
      await _dataSource.logout(refreshToken: refreshToken);
    } catch (_) {}
    await DioClient.clearTokens();
  }

  Future<UserEntity?> getMe() async {
    final token = await DioClient.getAccessToken();
    if (token == null) return null;
    try {
      final user = await _dataSource.getMe();
      return UserEntity.fromJson(user.toJson());
    } catch (_) {
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(AuthRemoteDataSource(ref.read(dioClientProvider)));
});

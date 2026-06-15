import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import 'auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout({String? refreshToken}) async {
    await _dio.post(
      ApiEndpoints.logout,
      data: refreshToken != null ? {'refreshToken': refreshToken} : null,
    );
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    final raw = response.data as Map<String, dynamic>;
    return raw['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _dio.post(ApiEndpoints.resetPassword, data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }
}

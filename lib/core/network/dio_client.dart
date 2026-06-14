import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  AppException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

const _storage = FlutterSecureStorage();
const _tokenKey = 'access_token';
const _refreshKey = 'refresh_token';

class DioClient {
  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${ApiEndpoints.baseUrl}${ApiEndpoints.apiPrefix}',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(_dio));
  }

  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  static Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() => _storage.read(key: _tokenKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  static Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await DioClient.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await DioClient.getRefreshToken();
        if (refreshToken == null) throw Exception('No refresh token');

        final response = await _dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final newAccessToken = response.data['accessToken'] as String;
        await DioClient.saveTokens(accessToken: newAccessToken);

        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await DioClient.clearTokens();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
      return;
    }

    final message = _extractMessage(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: AppException(message, statusCode: err.response?.statusCode),
        response: err.response,
        type: err.type,
      ),
    );
  }

  String _extractMessage(DioException err) {
    try {
      final data = err.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Something went wrong';
      }
    } catch (_) {}
    return err.message ?? 'Network error occurred';
  }
}

final dioClientProvider = Provider<Dio>((ref) => DioClient.instance.dio);

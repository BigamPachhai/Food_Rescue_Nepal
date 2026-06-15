import 'dart:async';
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

const _androidOptions = AndroidOptions(encryptedSharedPreferences: true);
const _storage = FlutterSecureStorage(aOptions: _androidOptions);
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
  // Queue of completers waiting for the refresh to finish.
  // Each entry is (completer, original requestOptions).
  final List<({Completer<String> completer, RequestOptions options})> _pendingQueue = [];

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
    if (err.response?.statusCode == 401) {
      // If a refresh is already in flight, queue this request instead of
      // triggering a second refresh (which would fail — old token already rotated).
      if (_isRefreshing) {
        final completer = Completer<String>();
        _pendingQueue.add((completer: completer, options: err.requestOptions));
        try {
          final newToken = await completer.future;
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(retryOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          handler.reject(err);
        }
        return;
      }

      _isRefreshing = true;
      try {
        final refreshToken = await DioClient.getRefreshToken();
        if (refreshToken == null) throw Exception('No refresh token');

        final response = await _dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        // Response envelope: { success, data: { accessToken, refreshToken }, message }
        final data = response.data['data'] as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String?;
        await DioClient.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Resolve queued requests with the new token.
        for (final pending in _pendingQueue) {
          pending.completer.complete(newAccessToken);
        }
        _pendingQueue.clear();

        // Retry the original failing request.
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed — clear tokens and reject all queued requests.
        await DioClient.clearTokens();
        for (final pending in _pendingQueue) {
          pending.completer.completeError('Refresh failed');
        }
        _pendingQueue.clear();
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
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        break;
    }
    try {
      final data = err.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg as String? ?? 'Something went wrong';
      }
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }
}

final dioClientProvider = Provider<Dio>((ref) => DioClient.instance.dio);

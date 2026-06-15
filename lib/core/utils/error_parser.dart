import 'package:dio/dio.dart';

enum ErrorType { network, server, auth, timeout, unknown }

class AppError {
  const AppError({required this.type, required this.message});

  final ErrorType type;
  final String message;

  static AppError from(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const AppError(
            type: ErrorType.timeout,
            message: 'Request timed out. Check your connection and try again.',
          );
        case DioExceptionType.connectionError:
          return const AppError(
            type: ErrorType.network,
            message:
                'No internet connection. Check your network and try again.',
          );
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? 0;
          if (code == 401 || code == 403) {
            return const AppError(
              type: ErrorType.auth,
              message: 'Your session has expired. Please log in again.',
            );
          }
          if (code >= 500) {
            return const AppError(
              type: ErrorType.server,
              message: 'Server error. Please try again later.',
            );
          }
          final data = error.response?.data;
          final msg = data is Map
              ? (data['message'] ?? data['error'] ?? 'Something went wrong.')
              : 'Something went wrong.';
          return AppError(type: ErrorType.unknown, message: msg.toString());
        default:
          break;
      }
    }
    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('no address') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable')) {
      return const AppError(
        type: ErrorType.network,
        message: 'No internet connection. Check your network and try again.',
      );
    }
    if (str.contains('connection timed out') || str.contains('timeout')) {
      return const AppError(
        type: ErrorType.timeout,
        message: 'Request timed out. Check your connection and try again.',
      );
    }
    return AppError(type: ErrorType.unknown, message: _clean(error.toString()));
  }

  static String _clean(String raw) {
    // Strip DioException prefix to avoid cryptic messages
    if (raw.startsWith('DioException') || raw.startsWith('Exception:')) {
      final idx = raw.indexOf(':');
      if (idx != -1 && idx < raw.length - 1) {
        return raw.substring(idx + 1).trim();
      }
    }
    return raw;
  }
}

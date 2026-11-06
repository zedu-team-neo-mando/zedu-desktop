import 'package:zedu/core/core.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required SecureStorageService storage, required Dio dio})
    : _storage = storage,
      _dio = dio;

  final SecureStorageService _storage;
  final Dio _dio;
  VoidCallback? onUnauthorized;

  /// Called when a request fails with 401. Returns a fresh access token, or
  /// null when none is available.
  Future<String?> Function()? onRefreshToken;

  static const _retriedKey = 'authRetried';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (error) {
      // Secure storage can throw (for example from corrupted stored data).
      // Send the request without a token so the call still completes and the
      // normal 401 handling takes over, instead of hanging forever.
      AppLogger.w(
        'Could not read the access token: $error',
        tag: 'AuthInterceptor',
      );
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;
    final sentAuth = request.headers['Authorization']?.toString() ?? '';

    String? refreshed;
    try {
      refreshed = await onRefreshToken?.call();
    } catch (error) {
      AppLogger.w(
        'Could not refresh the access token: $error',
        tag: 'AuthInterceptor',
      );
    }

    if (refreshed != null &&
        refreshed.isNotEmpty &&
        'Bearer $refreshed' != sentAuth) {
      try {
        await _storage.saveAccessToken(refreshed);
      } catch (error) {
        AppLogger.w(
          'Could not store the refreshed access token: $error',
          tag: 'AuthInterceptor',
        );
      }
      request
        ..extra[_retriedKey] = true
        ..headers['Authorization'] = 'Bearer $refreshed';
      try {
        final response = await _dio.fetch<dynamic>(request);
        handler.resolve(response);
        return;
      } on DioException catch (retryError) {
        if (retryError.response?.statusCode != 401) {
          handler.next(retryError);
          return;
        }
      }
    }

    try {
      await _storage.deleteAccessToken();
    } catch (error) {
      AppLogger.w(
        'Could not delete the access token: $error',
        tag: 'AuthInterceptor',
      );
    }
    onUnauthorized?.call();
    handler.next(err);
  }
}

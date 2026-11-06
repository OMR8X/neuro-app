import 'dart:async';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api_constants.dart';

typedef TokenRefreshCallback = Future<String?> Function();

/// Intercepts 401 Unauthorized / JWT-expired responses, refreshes the Supabase
/// session once, and retries the original request with the new token.
///
/// Features:
///   • Concurrency-safe: parallel 401 failures queue behind a single refresh call.
///   • Dual-phase: intercepts both onResponse (for validateStatus: true) and onError.
///   • Anti-loop: retried requests carry [kRetried] header so they are never intercepted twice.
///   • Testable: pass [onRefreshToken] to inject a fake refresh function in tests.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    TokenRefreshCallback? onRefreshToken,
  }) : _refreshToken = onRefreshToken ?? _supabaseRefresh;

  final Dio dio;
  final TokenRefreshCallback _refreshToken;

  static const String kRetried = 'x-auth-retried';

  Future<String?>? _inFlightRefresh;

  static Future<String?> _supabaseRefresh() async {
    try {
      final res = await Supabase.instance.client.auth.refreshSession();
      return res.session?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Ensures multiple parallel 401 responses share a single refresh call
  /// preventing Supabase refresh-token rotation race conditions.
  Future<String?> _synchronizedRefresh() async {
    if (_inFlightRefresh != null) {
      return _inFlightRefresh!;
    }
    final future = _refreshToken();
    _inFlightRefresh = future;
    try {
      return await future;
    } finally {
      _inFlightRefresh = null;
    }
  }

  bool _isAuthError(Response? response) {
    if (response == null) return false;
    if (response.statusCode == 401) return true;
    final data = response.data;
    if (data is Map) {
      final code = data['code']?.toString();
      if (code != null && code.startsWith('PGRST3')) return true;

      final text = (data['message']?.toString() ?? data['error']?.toString() ?? '').toLowerCase();
      if (text.contains('jwt') ||
          text.contains('token expired') ||
          text.contains('claim') ||
          text.contains('unauthorized')) {
        return true;
      }
    }

    if (response.statusCode == 403) {
      final text = response.data?.toString().toLowerCase() ?? '';
      if (text.contains('exp') || text.contains('claim') || text.contains('jwt') || text.contains('token')) {
        return true;
      }
    }
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions opts, String token) {
    opts.headers[kRetried] = 'true';
    opts.headers[ApiHeaders.headerAuthorizationKey] =
        '${ApiHeaders.headerAuthorizationBearer} $token';
    return dio.fetch(opts);
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    final opts = response.requestOptions;
    if (!_isAuthError(response) || opts.headers.containsKey(kRetried)) {
      return handler.next(response);
    }
    try {
      final token = await _synchronizedRefresh();
      if (token == null || token.isEmpty) return handler.next(response);
      handler.resolve(await _retry(opts, token));
    } catch (_) {
      handler.next(response);
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    if (!_isAuthError(err.response) || opts.headers.containsKey(kRetried)) {
      return handler.next(err);
    }
    try {
      final token = await _synchronizedRefresh();
      if (token == null || token.isEmpty) return handler.next(err);
      handler.resolve(await _retry(opts, token));
    } catch (_) {
      handler.next(err);
    }
  }
}

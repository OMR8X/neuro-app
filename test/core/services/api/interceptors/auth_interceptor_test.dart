import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_app/core/services/api/api_constants.dart';
import 'package:neuro_app/core/services/api/interceptors/auth_interceptor.dart';

/// Minimal fake HTTP adapter — returns whatever [handler] produces for each call.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions, int callIndex) _handler;
  int _callCount = 0;

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) {
    return _handler(options, _callCount++);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

/// Builds a [Dio] with [AuthInterceptor] and a fake adapter.
Dio _buildDio({
  required Future<String?> Function() onRefreshToken,
  required Future<ResponseBody> Function(RequestOptions opts, int callIndex) adapter,
  bool validateStatus = true,
}) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://test.example',
    validateStatus: validateStatus ? (_) => true : null,
  ));
  dio.httpClientAdapter = _FakeAdapter(adapter);
  dio.interceptors.add(AuthInterceptor(dio: dio, onRefreshToken: onRefreshToken));
  return dio;
}

void main() {
  group('AuthInterceptor', () {
    // ─── 1. Happy path ────────────────────────────────────────────────────────
    test('200 OK passes through without calling refresh', () async {
      var refreshCalled = false;

      final dio = _buildDio(
        onRefreshToken: () async {
          refreshCalled = true;
          return 'new-token';
        },
        adapter: (_, _) async => _jsonBody(200, {'data': 'ok'}),
      );

      final res = await dio.get('/test');

      expect(res.statusCode, 200);
      expect(refreshCalled, isFalse);
    });

    // ─── 2. 401 status code ───────────────────────────────────────────────────
    test('401 status → refreshes token and retries with new Authorization header', () async {
      const newToken = 'refreshed-token-abc';
      String? capturedAuthHeader;

      final dio = _buildDio(
        onRefreshToken: () async => newToken,
        adapter: (opts, callIndex) async {
          capturedAuthHeader = opts.headers[ApiHeaders.headerAuthorizationKey]?.toString();
          return callIndex == 0
              ? _jsonBody(401, {'message': 'Unauthorized'})
              : _jsonBody(200, {'data': 'success'});
        },
      );

      final res = await dio.get('/protected');

      expect(res.statusCode, 200);
      expect(capturedAuthHeader, '${ApiHeaders.headerAuthorizationBearer} $newToken');
    });

    // ─── 3. PGRST301 in body ──────────────────────────────────────────────────
    test('200 with PGRST301 code in body → refreshes and retries', () async {
      var refreshCalled = false;

      final dio = _buildDio(
        onRefreshToken: () async {
          refreshCalled = true;
          return 'new-token';
        },
        adapter: (_, callIndex) async => callIndex == 0
            ? _jsonBody(200, {'code': 'PGRST301', 'message': 'JWT expired'})
            : _jsonBody(200, {'data': 'ok'}),
      );

      final res = await dio.get('/rpc/fn');

      expect(refreshCalled, isTrue);
      expect(res.statusCode, 200);
    });

    // ─── 4. JWT expired in message ────────────────────────────────────────────
    test('401 with "JWT expired" message → refreshes and retries', () async {
      var callCount = 0;

      final dio = _buildDio(
        onRefreshToken: () async => 'new-token',
        adapter: (_, _) async {
          callCount++;
          return callCount == 1
              ? _jsonBody(401, {'message': 'JWT expired'})
              : _jsonBody(200, {'data': 'ok'});
        },
      );

      final res = await dio.get('/test');

      expect(callCount, 2);
      expect(res.statusCode, 200);
    });

    // ─── 5. Refresh returns null (offline) ────────────────────────────────────
    test('refresh returns null → passes original 401 response through without crashing', () async {
      final dio = _buildDio(
        onRefreshToken: () async => null,
        adapter: (_, _) async => _jsonBody(401, {'message': 'JWT expired'}),
      );

      final res = await dio.get('/test');

      expect(res.statusCode, 401);
    });

    // ─── 6. Anti-loop guard ───────────────────────────────────────────────────
    test('x-auth-retried header → refresh is never called', () async {
      var refreshCalled = false;
      var adapterCallCount = 0;

      final dio = _buildDio(
        onRefreshToken: () async {
          refreshCalled = true;
          return 'should-not-be-used';
        },
        adapter: (_, _) async {
          adapterCallCount++;
          return _jsonBody(401, {'message': 'JWT expired'});
        },
      );

      final res = await dio.get(
        '/test',
        options: Options(headers: {AuthInterceptor.kRetried: 'true'}),
      );

      expect(refreshCalled, isFalse, reason: 'refresh must not run on an already-retried request');
      expect(adapterCallCount, 1);
      expect(res.statusCode, 401);
    });

    // ─── 7. onError 401 path ──────────────────────────────────────────────────
    test('DioException with 401 → refreshes and resolves with retried response', () async {
      var callCount = 0;

      final dio = _buildDio(
        onRefreshToken: () async => 'fresh-token',
        validateStatus: false,
        adapter: (_, _) async {
          callCount++;
          return callCount == 1
              ? _jsonBody(401, {'message': 'Unauthorized'})
              : _jsonBody(200, {'data': 'retried'});
        },
      );

      final res = await dio.get('/test');

      expect(callCount, 2);
      expect(res.statusCode, 200);
    });

    // ─── 8. PGRST303 (JWT expired) ───────────────────────────────────────────
    test('200 with PGRST303 code in body → refreshes and retries', () async {
      var refreshCalled = false;

      final dio = _buildDio(
        onRefreshToken: () async {
          refreshCalled = true;
          return 'new-token';
        },
        adapter: (_, callIndex) async => callIndex == 0
            ? _jsonBody(200, {'code': 'PGRST303', 'message': 'JWT expired'})
            : _jsonBody(200, {'data': 'ok'}),
      );

      final res = await dio.get('/rpc/fn');

      expect(refreshCalled, isTrue);
      expect(res.statusCode, 200);
    });

    // ─── 9. PGRST302 (claims / anon error) ───────────────────────────────────
    test('200 with PGRST302 code in body → refreshes and retries', () async {
      var refreshCalled = false;

      final dio = _buildDio(
        onRefreshToken: () async {
          refreshCalled = true;
          return 'new-token';
        },
        adapter: (_, callIndex) async => callIndex == 0
            ? _jsonBody(200, {'code': 'PGRST302', 'message': 'JWSError JWSInvalidSignature'})
            : _jsonBody(200, {'data': 'ok'}),
      );

      final res = await dio.get('/rpc/fn');

      expect(refreshCalled, isTrue);
      expect(res.statusCode, 200);
    });

    // ─── 10. Case-insensitive "token expired" ────────────────────────────────
    test('200 with lowercase "token expired" in message → refreshes and retries', () async {
      var refreshCalled = false;

      final dio = _buildDio(
        onRefreshToken: () async {
          refreshCalled = true;
          return 'new-token';
        },
        adapter: (_, callIndex) async => callIndex == 0
            ? _jsonBody(200, {'message': 'access token expired'})
            : _jsonBody(200, {'data': 'ok'}),
      );

      final res = await dio.get('/rpc/fn');

      expect(refreshCalled, isTrue);
      expect(res.statusCode, 200);
    });

    // ─── 11. HTTP 403 with "exp" claim timestamp check failed ────────────────
    test('403 with "exp" claim timestamp check failed → refreshes and retries', () async {
      var callCount = 0;

      final dio = _buildDio(
        onRefreshToken: () async => 'new-token',
        adapter: (_, _) async {
          callCount++;
          return callCount == 1
              ? _jsonBody(403, {'message': '"exp" claim timestamp check failed'})
              : _jsonBody(200, {'data': 'ok'});
        },
      );

      final res = await dio.get('/storage/v1/object/pdf');

      expect(callCount, 2);
      expect(res.statusCode, 200);
    });

    // ─── 12. Edge Function error field shape { "error": "Unauthorized" } ─────
    test('200/400 with "error": "Unauthorized" in body → refreshes and retries', () async {
      var refreshCalled = false;

      final dio = _buildDio(
        onRefreshToken: () async {
          refreshCalled = true;
          return 'new-token';
        },
        adapter: (_, callIndex) async => callIndex == 0
            ? _jsonBody(200, {'error': 'Unauthorized'})
            : _jsonBody(200, {'data': 'ok'}),
      );

      final res = await dio.get('/functions/v1/compress-pdf');

      expect(refreshCalled, isTrue);
      expect(res.statusCode, 200);
    });

    // ─── 13. Concurrency check ────────────────────────────────────────────────
    test('Concurrent 401 requests trigger only ONE refresh session call', () async {
      var refreshCount = 0;
      final completer = Completer<String?>();

      final dio = _buildDio(
        onRefreshToken: () async {
          refreshCount++;
          return completer.future;
        },
        adapter: (opts, callIndex) async {
          final isRetry = opts.headers.containsKey(AuthInterceptor.kRetried);
          return isRetry
              ? _jsonBody(200, {'data': 'retried'})
              : _jsonBody(401, {'message': 'JWT expired'});
        },
      );

      // Fire 3 simultaneous requests
      final future1 = dio.get('/endpoint1');
      final future2 = dio.get('/endpoint2');
      final future3 = dio.get('/endpoint3');

      // Give all three requests a moment to reach the 401 response and enter _synchronizedRefresh
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Complete refresh while all 3 requests are waiting
      completer.complete('shared-refreshed-token');

      final results = await Future.wait([future1, future2, future3]);

      expect(refreshCount, 1, reason: 'Parallel 401 requests must share the same in-flight refresh');
      for (final res in results) {
        expect(res.statusCode, 200);
      }
    });
  });
}

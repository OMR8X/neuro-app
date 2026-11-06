import 'package:neuro_app/core/services/api/supabase/supabase_settings.dart';
import 'package:dio/dio.dart';
import 'package:neuro_app/core/services/api/api_constants.dart';
import 'package:neuro_app/core/services/api/dio_factory.dart';
import 'package:neuro_app/core/services/api/interceptors/auth_interceptor.dart';
import 'package:neuro_app/core/services/api/token_provider.dart';

abstract class ApiClient {
  /// get request
  Future<Response> get(
    String uri, {
    Map<String, dynamic>? headers,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    ResponseType? responseType,
    Options? options,
    CancelToken? cancelToken,
  });

  /// post request
  Future<Response> post(
    String uri, {
    Object? body,
    Map<String, dynamic>? headers,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    ResponseType? responseType,
    Options? options,
    Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  });

  /// update request
  Future<Response> put(
    String uri, {
    Object? body,
    Map<String, dynamic>? headers,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    ResponseType? responseType,
    Options? options,
    CancelToken? cancelToken,
  });

  /// delete request
  Future<Response> delete(
    String uri, {
    Object? body,
    Map<String, dynamic>? headers,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    ResponseType? responseType,
    Options? options,
    CancelToken? cancelToken,
  });
}

class DioClient implements ApiClient {
  //
  late final DioFactory _dioFactory;
  late final Map<String, String> defaultHeaders;
  late final BaseOptions options;
  late final TokenProvider _tokenProvider;
  late final Dio _dio;
  //
  DioClient({
    TokenProvider? tokenProvider,
    TokenRefreshCallback? onRefreshToken,
  }) {
    //
    _tokenProvider = tokenProvider ?? SupabaseTokenProvider();
    //
    _dioFactory = DioFactory();
    //
    defaultHeaders = <String, String>{
      ApiHeaders.headerContentTypeKey: ApiHeaders.headerContentTypeJson,
      ApiHeaders.headerAcceptKey: ApiHeaders.headerContentTypeJson,
      ApiHeaders.headerApiKey: SupabaseSettings.anonKey,
    };

    //
    options = BaseOptions(
      headers: defaultHeaders,
      baseUrl: ApiSettings.baseUrl,
      receiveTimeout: const Duration(seconds: ApiSettings.receiveTimeout),
      sendTimeout: const Duration(seconds: ApiSettings.sendTimeout),
      connectTimeout: const Duration(seconds: ApiSettings.connectTimeout),
      validateStatus: (int? status) {
        return true;
      },
    );

    _dio = _dioFactory();
    _dio.options = options;
    _dio.interceptors.add(AuthInterceptor(dio: _dio, onRefreshToken: onRefreshToken));
  }
  //

  @override
  Future<Response> get(
    String uri, {
    Map<String, dynamic>? headers,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    ResponseType? responseType,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final mergedOptions = await _buildOptions(
      headers: headers,
      responseType: responseType,
      baseOptions: options,
    );
    return _dio.get(
      uri,
      queryParameters: queryParameters,
      options: mergedOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response> post(
    String uri, {
    Object? body,
    Map<String, dynamic>? headers,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    ResponseType? responseType,
    Options? options,
    Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final mergedOptions = await _buildOptions(
      headers: headers,
      responseType: responseType,
      baseOptions: options,
    );
    return _dio.post(
      uri,
      data: body,
      queryParameters: queryParameters,
      options: mergedOptions,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response> put(
    String uri, {
    Object? body,
    Map<String, dynamic>? headers,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    ResponseType? responseType,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final mergedOptions = await _buildOptions(
      headers: headers,
      responseType: responseType,
      baseOptions: options,
    );
    return _dio.put(
      uri,
      data: body,
      queryParameters: queryParameters,
      options: mergedOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response> delete(
    String uri, {
    Object? body,
    Map<String, dynamic>? headers,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    ResponseType? responseType,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final mergedOptions = await _buildOptions(
      headers: headers,
      responseType: responseType,
      baseOptions: options,
    );
    return _dio.delete(
      uri,
      data: body,
      queryParameters: queryParameters,
      options: mergedOptions,
      cancelToken: cancelToken,
    );
  }

  Future<Options> _buildOptions({
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    Options? baseOptions,
  }) async {
    final Map<String, dynamic> effectiveHeaders = <String, dynamic>{...defaultHeaders};

    if (headers != null) {
      effectiveHeaders.addAll(headers);
    }

    final String? token = await _tokenProvider.getToken();

    if (token != null && token.isNotEmpty) {
      effectiveHeaders[ApiHeaders.headerAuthorizationKey] =
          '${ApiHeaders.headerAuthorizationBearer} $token';
    } else {
      effectiveHeaders.remove(ApiHeaders.headerAuthorizationKey);
    }

    if (baseOptions?.headers != null) {
      effectiveHeaders.addAll(baseOptions!.headers!);
    }

    return (baseOptions ?? Options()).copyWith(
      headers: effectiveHeaders,
      responseType: responseType ?? baseOptions?.responseType,
    );
  }
}

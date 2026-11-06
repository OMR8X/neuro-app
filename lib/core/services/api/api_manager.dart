import 'api_client.dart';
import 'interceptors/auth_interceptor.dart';
import 'token_provider.dart';

class ApiManager {
  late final ApiClient _apiClient;

  /// create api client instance
  ApiManager({
    TokenProvider? tokenProvider,
    TokenRefreshCallback? onRefreshToken,
  }) {
    _apiClient = DioClient(
      tokenProvider: tokenProvider,
      onRefreshToken: onRefreshToken,
    );
  }

  /// return api client instance
  ApiClient call() {
    return _apiClient;
  }
}

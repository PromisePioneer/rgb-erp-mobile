import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

/// Interceptor that adds authentication token to requests
class AuthInterceptor extends Interceptor {
  final StorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login endpoint
    if (options.path.contains('/login')) {
      return handler.next(options);
    }

    // Add auth token if available
    // Check if this is a client API request
    final isClientRequest = options.path.startsWith('/client');

    String? token;
    if (isClientRequest) {
      token = await _storage.clientAuthToken;
    } else {
      token = await _storage.authToken;
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add default headers
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isClientRequest = path.startsWith('/client');

      if (isClientRequest) {
        await _storage.clearClientAuthData();
      } else {
        await _storage.clearAuthData();
      }
    }

    return handler.next(err);
  }
}

/// Interceptor that logs requests/responses in debug mode
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: Add debug logging
    // print('REQUEST[${options.method}] => PATH: ${options.path}');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // TODO: Add debug logging
    // print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: Add debug logging
    // print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    return handler.next(err);
  }
}

/// Creates configured Dio instance
class ApiClientFactory {
  final StorageService storage;

  ApiClientFactory({required this.storage});

  Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(AuthInterceptor(storage));
    dio.interceptors.add(LoggingInterceptor());

    return dio;
  }
}

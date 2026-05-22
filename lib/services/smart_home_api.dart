import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thingsboard_app/constants/app_constants.dart';
import 'package:thingsboard_app/services/gateway_auth_service.dart';

final smartHomeDioProvider = Provider<Dio>((ref) {
  final host = Uri.tryParse(ThingsboardAppConstants.thingsBoardApiEndpoint)?.host ?? '192.168.1.100';
  final dio = Dio(BaseOptions(
    baseUrl: 'http://$host:8080',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(GatewayAuthInterceptor(ref, dio: dio));
  dio.interceptors.add(RetryInterceptor(dio: dio));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});

class GatewayAuthInterceptor extends Interceptor {
  GatewayAuthInterceptor(this._ref, {this.dio});
  final Ref _ref;
  final Dio? dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(gatewayTokenProvider);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && dio != null && !_isRefreshEndpoint(err)) {
      final service = _ref.read(gatewayAuthProvider);
      final refreshed = await service.refresh();
      if (refreshed) {
        final token = _ref.read(gatewayTokenProvider);
        if (token != null) {
          try {
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $token';
            final res = await dio!.fetch(opts);
            handler.resolve(res);
            return;
          } catch (_) {}
        }
      }
    }
    handler.next(err);
  }

  bool _isRefreshEndpoint(DioException err) =>
    err.requestOptions.path.contains('/api/auth/refresh');
}

class RetryInterceptor extends Interceptor {
  RetryInterceptor({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static const _maxAttempts = 2;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && !_isRetry(err)) {
      try {
        final res = await _dio.fetch(_retryOptions(err));
        handler.resolve(res);
        return;
      } catch (_) {}
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) => switch (err.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.connectionError =>
      true,
    _ => false,
  };

  bool _isRetry(DioException err) =>
    err.requestOptions.extra['retry_count'] != null &&
    (err.requestOptions.extra['retry_count'] as int) >= _maxAttempts;

  RequestOptions _retryOptions(DioException err) {
    final opts = err.requestOptions;
    opts.extra['retry_count'] = (opts.extra['retry_count'] as int? ?? 0) + 1;
    return opts;
  }
}

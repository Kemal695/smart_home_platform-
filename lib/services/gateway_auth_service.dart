import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:thingsboard_app/constants/app_constants.dart';

class _GatewayTokenCache {
  String? accessToken;
  String? refreshToken;
}
final _cache = _GatewayTokenCache();
final _storage = FlutterSecureStorage();

final gatewayTokenProvider = StateProvider<String?>((ref) => _cache.accessToken);

final gatewayAuthProvider = Provider<GatewayAuthService>((ref) {
  final host = Uri.tryParse(ThingsboardAppConstants.thingsBoardApiEndpoint)?.host ?? '192.168.1.100';
  return GatewayAuthService(host, ref);
});

class GatewayAuthService {
  GatewayAuthService(this._host, this._ref);

  final String _host;
  final Ref _ref;

  Future<void> storeCredentials(String email, String password) async {
    await Future.wait([
      _storage.write(key: 'gateway_email', value: email),
      _storage.write(key: 'gateway_password', value: password),
    ]);
  }

  void clearCredentials() {
    _storage.delete(key: 'gateway_email');
    _storage.delete(key: 'gateway_password');
  }

  Future<bool> tryAutoLogin() async {
    final results = await Future.wait([
      _storage.read(key: 'gateway_email'),
      _storage.read(key: 'gateway_password'),
      _storage.read(key: 'gateway_token'),
    ]);
    if (results[2] != null) {
      _cache.accessToken = results[2] as String;
      _ref.read(gatewayTokenProvider.notifier).state = results[2] as String;
      return true;
    }
    final email = results[0] as String?;
    final password = results[1] as String?;
    if (email != null && password != null) {
      return login(email, password);
    }
    return false;
  }

  Dio _dio() => Dio(BaseOptions(
    baseUrl: 'http://$_host:8080',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<bool> register(String name, String email, String password) async {
    try {
      await _dio().post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final res = await _dio().post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final token = res.data?['accessToken'] as String?;
      final refresh = res.data?['refreshToken'] as String?;
      if (token != null) {
        _cache.accessToken = token;
        _cache.refreshToken = refresh;
        _ref.read(gatewayTokenProvider.notifier).state = token;
        await Future.wait([
          _storage.write(key: 'gateway_token', value: token),
          if (refresh != null) _storage.write(key: 'gateway_refresh', value: refresh),
        ]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> refresh() async {
    final refreshToken = _cache.refreshToken ?? await _storage.read(key: 'gateway_refresh');
    if (refreshToken == null) return false;
    try {
      final res = await _dio().post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final token = res.data?['accessToken'] as String?;
      final newRefresh = res.data?['refreshToken'] as String?;
      if (token != null) {
        _cache.accessToken = token;
        if (newRefresh != null) _cache.refreshToken = newRefresh;
        _ref.read(gatewayTokenProvider.notifier).state = token;
        await Future.wait([
          _storage.write(key: 'gateway_token', value: token),
          if (newRefresh != null) _storage.write(key: 'gateway_refresh', value: newRefresh),
        ]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> tryLoadStoredToken() async {
    final results = await Future.wait([
      _storage.read(key: 'gateway_token'),
      _storage.read(key: 'gateway_refresh'),
    ]);
    final token = results[0];
    final refresh = results[1];
    if (token != null) {
      _cache.accessToken = token;
      _cache.refreshToken = refresh;
      _ref.read(gatewayTokenProvider.notifier).state = token;
      return true;
    }
    return false;
  }

  void logout() {
    _cache.accessToken = null;
    _cache.refreshToken = null;
    _ref.read(gatewayTokenProvider.notifier).state = null;
    _storage.delete(key: 'gateway_token');
    _storage.delete(key: 'gateway_refresh');
    clearCredentials();
  }
}

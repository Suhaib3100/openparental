import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

/// Talks to the monii backend. Adds the access token, and on a 401 silently
/// refreshes (rotating refresh token) and retries the failed request once.
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String baseUrl;

  ApiClient({required this.baseUrl, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401 && await _tryRefresh()) {
          try {
            final req = e.requestOptions;
            final token = await _storage.read(key: 'access');
            req.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch<dynamic>(req);
            return handler.resolve(response);
          } catch (_) {
            // fall through to the original error
          }
        }
        handler.next(e);
      },
    ));
  }

  // ---- auth ----

  Future<AuthResult> login(String email, String password) async {
    final r = await _dio.post<dynamic>('/auth/login',
        data: {'email': email, 'password': password});
    return _persist(AuthResult.fromJson(r.data as Map<String, dynamic>));
  }

  Future<AuthResult> register(String email, String password) async {
    final r = await _dio.post<dynamic>('/auth/register',
        data: {'email': email, 'password': password});
    return _persist(AuthResult.fromJson(r.data as Map<String, dynamic>));
  }

  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (_) {
      // best effort
    }
    await _storage.deleteAll();
  }

  Future<bool> hasSession() async =>
      (await _storage.read(key: 'access')) != null;

  Future<AuthResult> _persist(AuthResult r) async {
    await _storage.write(key: 'access', value: r.accessToken);
    await _storage.write(key: 'refresh', value: r.refreshToken);
    return r;
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.read(key: 'refresh');
    if (refresh == null) return false;
    try {
      final r = await _dio
          .post<dynamic>('/auth/refresh', data: {'refreshToken': refresh});
      await _persist(AuthResult.fromJson(r.data as Map<String, dynamic>));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- devices ----

  Future<List<Device>> devices() async {
    final r = await _dio.get<dynamic>('/devices');
    return (r.data as List)
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- pairing ----

  Future<Pairing> createPairing() async {
    final r = await _dio.post<dynamic>('/pairings', data: <String, dynamic>{});
    return Pairing.fromJson(r.data as Map<String, dynamic>);
  }

  Future<String> pairingStatus(String id) async {
    final r = await _dio.get<dynamic>('/pairings/$id');
    return (r.data as Map<String, dynamic>)['status'] as String? ?? 'PENDING';
  }

  // ---- commands ----

  Future<void> sendCommand(String deviceId, String type,
      [Map<String, dynamic>? payload]) async {
    await _dio.post<dynamic>('/devices/$deviceId/commands', data: {
      'type': type,
      if (payload != null) 'payload': payload,
    });
  }

  // ---- policy ----

  Future<Map<String, dynamic>?> getPolicy() async {
    final r = await _dio.get<dynamic>('/policies');
    final data = r.data;
    if (data is Map<String, dynamic>) {
      return data['rules'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> updatePolicy(Map<String, dynamic> rules) async {
    await _dio.put<dynamic>('/policies', data: {'rules': rules});
  }

  // ---- alerts ----

  Future<List<AlertModel>> alerts() async {
    final r = await _dio.get<dynamic>('/alerts');
    return (r.data as List)
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAlertRead(String id) async {
    await _dio.post<dynamic>('/alerts/$id/read');
  }

  // ---- location ----

  Future<DeviceLocation?> latestLocation(String deviceId) async {
    final r = await _dio.get<dynamic>('/devices/$deviceId/locations/latest');
    final data = r.data;
    if (data is Map<String, dynamic>) return DeviceLocation.fromJson(data);
    return null;
  }
}

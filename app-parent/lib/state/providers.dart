import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/models.dart';

/// Backend base URL (editable on the login screen for dev).
final baseUrlProvider =
    StateProvider<String>((ref) => 'http://192.168.1.5:3000');

final apiProvider = Provider<ApiClient>((ref) {
  final base = ref.watch(baseUrlProvider);
  return ApiClient(baseUrl: base);
});

/// All devices in the family. Refresh with `ref.invalidate(devicesProvider)`.
final devicesProvider = FutureProvider<List<Device>>(
  (ref) => ref.watch(apiProvider).devices(),
);

/// The device the Devices tab is focused on (defaults to the first).
final selectedDeviceIdProvider = StateProvider<String?>((ref) => null);

/// Family-wide alert feed. Refresh with `ref.invalidate(alertsProvider)`.
final alertsProvider = FutureProvider<List<AlertModel>>(
  (ref) => ref.watch(apiProvider).alerts(),
);

class AuthState {
  final bool loading;
  final bool loggedIn;
  final String? error;
  const AuthState({this.loading = false, this.loggedIn = false, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AuthState(loading: true)) {
    _init();
  }

  Future<void> _init() async {
    final has = await ref.read(apiProvider).hasSession();
    state = AuthState(loggedIn: has);
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      await ref.read(apiProvider).login(email, password);
      _onSignedIn();
    } catch (e) {
      state = AuthState(error: _message(e));
    }
  }

  Future<void> register(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      await ref.read(apiProvider).register(email, password);
      _onSignedIn();
    } catch (e) {
      state = AuthState(error: _message(e));
    }
  }

  void _onSignedIn() {
    ref.invalidate(devicesProvider);
    ref.invalidate(alertsProvider);
    state = const AuthState(loggedIn: true);
  }

  Future<void> logout() async {
    await ref.read(apiProvider).logout();
    state = const AuthState(loggedIn: false);
  }

  String _message(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Network error';
    }
    return e.toString();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

/// Backend base URL (editable on the login screen for dev).
final baseUrlProvider =
    StateProvider<String>((ref) => 'http://10.0.2.2:3000');

final apiProvider = Provider<ApiClient>((ref) {
  final base = ref.watch(baseUrlProvider);
  return ApiClient(baseUrl: base);
});

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
      state = const AuthState(loggedIn: true);
    } catch (e) {
      state = AuthState(error: _message(e));
    }
  }

  Future<void> register(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      await ref.read(apiProvider).register(email, password);
      state = const AuthState(loggedIn: true);
    } catch (e) {
      state = AuthState(error: _message(e));
    }
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

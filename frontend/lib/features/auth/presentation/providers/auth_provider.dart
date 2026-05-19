import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? userFullName;
  final String? userEmail;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.userId,
    this.userFullName,
    this.userEmail,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
      return;
    }
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/users/me');
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userId: response.data['id'] as String?,
        userFullName: response.data['full_name'] as String?,
        userEmail: response.data['email'] as String?,
      );
    } catch (_) {
      await _storage.delete(key: 'access_token');
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['access_token'] as String;
    final user = response.data['user'] as Map<String, dynamic>;
    await _storage.write(key: 'access_token', value: token);
    state = AuthState(
      isAuthenticated: true,
      isLoading: false,
      userId: user['id'] as String?,
      userFullName: user['full_name'] as String?,
      userEmail: user['email'] as String?,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
    final token = response.data['access_token'] as String;
    final user = response.data['user'] as Map<String, dynamic>;
    await _storage.write(key: 'access_token', value: token);
    state = AuthState(
      isAuthenticated: true,
      isLoading: false,
      userId: user['id'] as String?,
      userFullName: user['full_name'] as String?,
      userEmail: user['email'] as String?,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

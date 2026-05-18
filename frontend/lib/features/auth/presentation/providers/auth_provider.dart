import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  const AuthState({this.isAuthenticated = false, this.userId});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.post('/auth/login', data: {'email': email, 'password': password});
    final token = response.data['access_token'] as String;
    final userId = response.data['user']['id'] as String;
    await _storage.write(key: 'access_token', value: token);
    state = AuthState(isAuthenticated: true, userId: userId);
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
    final userId = response.data['user']['id'] as String;
    await _storage.write(key: 'access_token', value: token);
    state = AuthState(isAuthenticated: true, userId: userId);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    state = const AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

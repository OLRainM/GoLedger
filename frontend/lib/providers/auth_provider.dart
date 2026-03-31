import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/token_storage.dart';
import '../services/auth_service.dart';

/// 登录状态
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState({this.status = AuthStatus.initial, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _service = AuthService();

  AuthNotifier() : super(AuthState()) {
    // 检查是否有缓存 token
    if (TokenStorage.hasToken()) {
      state = AuthState(status: AuthStatus.authenticated);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final resp = await _service.login(email: email, password: password);
      if (resp.isSuccess && resp.data != null) {
        await TokenStorage.saveToken(resp.data!.token);
        state = state.copyWith(status: AuthStatus.authenticated);
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: resp.message,
        );
        return false;
      }
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    }
  }

  Future<bool> register(String email, String password, String? nickname) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final resp = await _service.register(
        email: email,
        password: password,
        nickname: nickname,
      );
      if (resp.isSuccess) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: resp.message,
        );
        return false;
      }
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.removeToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return (e.response!.data as Map<String, dynamic>)['message'] as String? ??
          '网络请求失败';
    }
    return e.message ?? '网络请求失败';
  }
}


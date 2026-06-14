import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_models.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';
import '../../domain/user_entity.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _init();
  }

  final AuthRepository _repository;

  Future<void> _init() async {
    state = const AuthLoading();
    final user = await _repository.getMe();
    if (user != null) {
      state = AuthAuthenticated(user);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(LoginRequest(email: email, password: password));
      // ignore: avoid_print
      print('[AUTH] Login success: ${user.email} role=${user.role}');
      state = AuthAuthenticated(user);
    } catch (e, st) {
      // ignore: avoid_print
      print('[AUTH] Login error: $e\n$st');
      state = AuthError(e.toString());
    }
  }

  Future<void> register(RegisterRequest request) async {
    state = const AuthLoading();
    try {
      final user = await _repository.register(request);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  UserEntity? get currentUser {
    final s = state;
    if (s is AuthAuthenticated) return s.user;
    return null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

import 'user_entity.dart';
import '../data/auth_models.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// New Google user — account doesn't exist yet; app must ask for role before creating.
class AuthGoogleNewUser extends AuthState {
  final String firebaseIdToken;
  final GoogleUserData googleUserData;
  const AuthGoogleNewUser(this.firebaseIdToken, this.googleUserData);
}

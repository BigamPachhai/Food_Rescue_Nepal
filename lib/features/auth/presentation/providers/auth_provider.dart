import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/network/dio_client.dart';
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
      final user = await _repository
          .login(LoginRequest(email: email, password: password));
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(AppException.extractMessage(e));
    }
  }

  Future<void> register(RegisterRequest request) async {
    state = const AuthLoading();
    try {
      final user = await _repository.register(request);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(AppException.extractMessage(e));
    }
  }

  Future<void> googleSignIn() async {
    state = const AuthLoading();
    try {
      final gsi = GoogleSignIn();
      await gsi.signOut(); // Clear cached account so the picker always appears
      final googleUser = await gsi.signIn();
      if (googleUser == null) {
        state = const AuthUnauthenticated();
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Extract user data from Firebase user
      final firebaseUser = userCredential.user;
      final googleUserData = GoogleUserData(
        email: firebaseUser?.email ?? googleUser.email,
        name: firebaseUser?.displayName ?? googleUser.displayName ?? '',
        phone: firebaseUser?.phoneNumber,
        picture: firebaseUser?.photoURL ?? googleUser.photoUrl,
        firebaseIdToken: firebaseIdToken,
      );

      final user = await _repository.googleSignIn(firebaseIdToken);
      if (user == null) {
        // New user — needs to pick a role before account is created
        state = AuthGoogleNewUser(firebaseIdToken, googleUserData);
      } else {
        state = AuthAuthenticated(user);
      }
    } catch (e) {
      state = AuthError(AppException.extractMessage(e));
    }
  }

  /// Called after a new Google user selects their role.
  /// role must be 'CUSTOMER' or 'VENDOR'.
  Future<void> completeGoogleSignIn(
    String firebaseIdToken,
    String role, {
    String? businessName,
    String? businessType,
    String? address,
    double? lat,
    double? lng,
    String? phone,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.googleSignIn(
        firebaseIdToken,
        role: role,
        businessName: businessName,
        businessType: businessType,
        address: address,
        lat: lat,
        lng: lng,
        phone: phone,
      );
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state =
            const AuthError('Failed to complete sign-in. Please try again.');
      }
    } catch (e) {
      state = AuthError(AppException.extractMessage(e));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    state = const AuthUnauthenticated();
  }

  void setAuthenticated(UserEntity user) {
    state = AuthAuthenticated(user);
  }

  void updateUser({String? name, String? phone, String? avatarUrl}) {
    final s = state;
    if (s is AuthAuthenticated) {
      state = AuthAuthenticated(
          s.user.copyWith(name: name, phone: phone, avatarUrl: avatarUrl));
    }
  }

  UserEntity? get currentUser {
    final s = state;
    if (s is AuthAuthenticated) return s.user;
    return null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref.read(authRepositoryProvider));
  onSessionExpired = () => notifier.logout();
  return notifier;
});

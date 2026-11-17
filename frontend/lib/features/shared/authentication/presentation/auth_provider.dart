import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool hasCompletedSplash;
  final bool hasSeenOnboarding;
  final String? errorMessage;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String role; // 'Admin' or 'Driver'

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.hasCompletedSplash = false,
    this.hasSeenOnboarding = false,
    this.errorMessage,
    this.email,
    this.displayName,
    this.photoUrl,
    this.role = 'Admin',
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? hasCompletedSplash,
    bool? hasSeenOnboarding,
    String? errorMessage,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      hasCompletedSplash: hasCompletedSplash ?? this.hasCompletedSplash,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      errorMessage: errorMessage,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier() : super(const AuthState()) {
    _initAuthState();
  }

  void _initAuthState() {
    // Check initial user and listen to auth changes
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final storedRole = prefs.getString('user_role_${user.uid}') ??
            (user.email?.toLowerCase().contains('admin') ?? false ? 'Admin' : 'Driver');

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          role: storedRole,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          email: null,
          displayName: null,
          photoUrl: null,
        );
      }
    });
  }

  void completeSplash() {
    state = state.copyWith(hasCompletedSplash: true);
  }

  void completeOnboarding() {
    state = state.copyWith(hasSeenOnboarding: true);
  }

  /// Sign In with Email & Password
  Future<bool> login(String email, String password, {String role = 'Admin'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password must be at least 6 characters long.',
      );
      return false;
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = userCredential.user;
      final determinedRole = cleanEmail.toLowerCase().contains('admin') ? 'Admin' : role;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role_${user.uid}', determinedRole);
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        hasCompletedSplash: true,
        hasSeenOnboarding: true,
        email: user?.email ?? cleanEmail,
        displayName: user?.displayName,
        photoUrl: user?.photoURL,
        role: determinedRole,
        errorMessage: null,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Authentication error: ${e.toString()}',
      );
      return false;
    }
  }

  /// Sign Up with Email & Password
  Future<bool> signUp(
    String email,
    String password, {
    String name = '',
    String role = 'Driver',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password must be at least 6 characters long.',
      );
      return false;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = userCredential.user;
      if (name.isNotEmpty && user != null) {
        await user.updateDisplayName(name.trim());
      }

      final determinedRole = cleanEmail.toLowerCase().contains('admin') ? 'Admin' : role;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role_${user.uid}', determinedRole);
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        hasCompletedSplash: true,
        hasSeenOnboarding: true,
        email: user?.email ?? cleanEmail,
        displayName: name.isNotEmpty ? name.trim() : user?.displayName,
        photoUrl: user?.photoURL,
        role: determinedRole,
        errorMessage: null,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Sign In with Google
  Future<bool> signInWithGoogle({String role = 'Admin'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled Google sign-in prompt
        state = state.copyWith(isLoading: false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      final determinedRole = (user?.email?.toLowerCase().contains('admin') ?? false) ? 'Admin' : role;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role_${user.uid}', determinedRole);
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        hasCompletedSplash: true,
        hasSeenOnboarding: true,
        email: user?.email,
        displayName: user?.displayName,
        photoUrl: user?.photoURL,
        role: determinedRole,
        errorMessage: null,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google Sign-In failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Send Password Reset Link to Email
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset request failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Sign Out / Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Sign out notice: $e');
    }

    state = state.copyWith(
      isAuthenticated: false,
      errorMessage: null,
      email: null,
      displayName: null,
      photoUrl: null,
    );
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password entered.';
      case 'invalid-credential':
        return 'Invalid email or password credentials.';
      case 'email-already-in-use':
        return 'This email address is already registered. Please login instead.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled by an administrator.';
      case 'network-request-failed':
        return 'Network connection error. Please verify your internet connection.';
      case 'operation-not-allowed':
        return 'Sign-in method not enabled. Please enable it in Firebase Console.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few moments and try again.';
      default:
        return e.message ?? 'An unexpected authentication error occurred (${e.code}).';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

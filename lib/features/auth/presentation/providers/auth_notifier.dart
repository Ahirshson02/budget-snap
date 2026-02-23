import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/app_exception.dart';

/// State for auth operations.
/// Separate from [currentUserProvider] (which just reflects current session)
/// — this tracks the in-progress state of sign-in / sign-up / sign-out calls.
@immutable
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  final bool isLoading;
  final String? errorMessage;
  final User? user;

  bool get hasError => errorMessage != null;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      // Pass null explicitly to clear the error
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._client) : super(AuthState(
    user: Supabase.instance.client.auth.currentUser,
  ));

  final SupabaseClient _client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        user: response.user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        user: response.user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _client.auth.signOut();
      state = const AuthState();
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthNotifier(client);
});
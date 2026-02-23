import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Exposes the Supabase client as a Riverpod provider.
//
// Why wrap it? Two reasons:
// 1. Repositories depend on this provider, not on the Supabase singleton
//    directly — making repositories fully testable with a mock client.
// 2. It makes the dependency graph explicit and visible in DevTools.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Convenience provider for the current auth user.
// Returns null when no user is signed in.
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// Stream provider that reactively tracks auth state changes.
// Used by the router to redirect between auth and app screens.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
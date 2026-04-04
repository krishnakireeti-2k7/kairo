import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kairo/core/services/supabase_service.dart';

// Watches Supabase auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateChanges;
});

// Convenience provider: is the user signed in?
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session != null,
    loading: () => SupabaseService.isSignedIn,
    error: (_, __) => false,
  );
});

// Current user
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider); // rebuild when auth changes
  return SupabaseService.currentUser;
});

// Auth actions notifier
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await SupabaseService.signInWithGoogle();

      final user = SupabaseService.currentUser;

      if (user == null) {
        throw Exception("User is null after login");
      }

      // ✅ THIS IS THE MISSING PIECE
      await SupabaseService.client.from('users').upsert({
        'id': user.id,
        'email': user.email,
      });
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => SupabaseService.signOut());
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);

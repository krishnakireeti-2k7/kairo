import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kairo/core/constants/supabase_constants.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static bool get isSignedIn => client.auth.currentSession != null;

  static User? get currentUser => client.auth.currentUser;

  static Future<void> signInWithGoogle() async {
    // Placeholder for actual Google Sign-In logic
    await client.auth.signInWithOAuth(OAuthProvider.google);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}

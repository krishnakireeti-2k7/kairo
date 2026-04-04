import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kairo/features/auth/presentation/providers/auth_provider.dart';
import 'package:kairo/features/auth/presentation/screens/login_screen.dart';

// ✅ IMPORT YOUR REAL SCREENS
import 'package:kairo/features/logs/presentation/screens/home_screen.dart';
import 'package:kairo/features/logs/presentation/screens/log_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(isSignedInProvider);

  return GoRouter(
    initialLocation: authState ? '/home' : '/login',

    redirect: (context, state) {
      final signedIn = ref.read(isSignedInProvider);
      final isLoginRoute = state.matchedLocation == '/login';

      if (!signedIn && !isLoginRoute) return '/login';
      if (signedIn && isLoginRoute) return '/home';

      return null;
    },

    refreshListenable: _AuthListenable(ref),

    routes: [
      // 🔐 AUTH
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),

      // 🏠 HOME
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),

      // ➕ LOG SCREEN
      GoRoute(path: '/log', builder: (_, _) => const LogScreen()),

      // 🔁 OAuth callback
      GoRoute(path: '/login-callback', builder: (_, _) => const LoginScreen()),
    ],
  );
});

/// Makes GoRouter react to auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(isSignedInProvider, (_, _) {
      notifyListeners();
    });
  }
}

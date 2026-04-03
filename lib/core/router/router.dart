import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/features/auth/presentation/providers/auth_provider.dart';
import 'package:kairo/features/auth/presentation/screens/login_screen.dart';

// Placeholder screens for now
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Home – Insights')));
}

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
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      // Deep link for Supabase OAuth callback
      GoRoute(path: '/login-callback', builder: (_, __) => const LoginScreen()),
    ],
  );
});

/// Makes GoRouter react to auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(isSignedInProvider, (_, __) => notifyListeners());
  }
}

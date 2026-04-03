import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/router/router.dart';
import 'package:kairo/core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: KairoApp()));
}

class KairoApp extends ConsumerWidget {
  const KairoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Kairo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFA0C9FF),
          secondary: Color(0xFF7AD5D7),
          surface: Color(0xFF0C141B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0C141B),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
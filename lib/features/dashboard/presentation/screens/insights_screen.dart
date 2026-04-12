import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/widgets/app_bottom_navigation.dart';
import 'package:kairo/features/logs/presentation/providers/log_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(insightProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(insightProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: insightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $error', textAlign: TextAlign.center),
          ),
        ),
        data: (insight) =>
            Padding(padding: const EdgeInsets.all(16), child: Text(insight)),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

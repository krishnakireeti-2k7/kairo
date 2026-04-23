import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/widgets/app_bottom_navigation.dart';
import 'package:kairo/features/dashboard/presentation/providers/insight_provider.dart';

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(insightProvider);
              await ref.read(insightProvider.future);
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: insightAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    data: (insight) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(insight),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

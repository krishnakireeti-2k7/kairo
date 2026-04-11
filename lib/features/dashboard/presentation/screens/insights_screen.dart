import 'package:flutter/material.dart';
import 'package:kairo/core/widgets/app_bottom_navigation.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Insights',
      message: 'Insights Screen (Coming Soon)',
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const _PlaceholderScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(message, textAlign: TextAlign.center)),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

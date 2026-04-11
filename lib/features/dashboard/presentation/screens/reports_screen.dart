import 'package:flutter/material.dart';
import 'package:kairo/core/widgets/app_bottom_navigation.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Reports Screen (Coming Soon)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

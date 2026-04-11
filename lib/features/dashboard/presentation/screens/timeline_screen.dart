import 'package:flutter/material.dart';
import 'package:kairo/core/widgets/app_bottom_navigation.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Timeline Screen (Coming Soon)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

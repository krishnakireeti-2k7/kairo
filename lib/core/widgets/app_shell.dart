import 'package:flutter/material.dart';
import 'package:kairo/core/widgets/app_bottom_navigation.dart';
import 'package:kairo/features/chat/presentation/screens/chat_screen.dart';
import 'package:kairo/features/dashboard/presentation/screens/reports_screen.dart';
import 'package:kairo/features/dashboard/presentation/screens/timeline_screen.dart';
import 'package:kairo/features/logs/presentation/screens/home_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, required this.initialIndex});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;
  late int _currentIndex;

  static const _pages = <Widget>[
    HomeScreen(),
    ChatScreen(),
    TimelineScreen(),
    ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex != _currentIndex) {
      _currentIndex = widget.initialIndex;
      _pageController.jumpToPage(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (_currentIndex == index) {
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) {
            return;
          }

          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}

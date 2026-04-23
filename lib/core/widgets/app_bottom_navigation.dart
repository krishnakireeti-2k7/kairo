import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = <_NavItem>[
    _NavItem(route: '/home', label: 'HOME', icon: Icons.home_rounded),
    _NavItem(route: '/chat', label: 'CHAT', icon: Icons.forum_rounded),
    _NavItem(
      route: '/timeline',
      label: 'TIMELINE',
      icon: Icons.timeline_rounded,
    ),
    _NavItem(
      route: '/reports',
      label: 'REPORTS',
      icon: Icons.description_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C151C).withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFDBE3ED).withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFDCE9FF),
          unselectedItemColor: const Color(0xFF8894A3),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(letterSpacing: 0.7),
          unselectedLabelStyle: const TextStyle(letterSpacing: 0.7),
          items: _items.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData icon;

  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}

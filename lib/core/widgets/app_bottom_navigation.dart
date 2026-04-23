import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key});

  static const _items = <_NavItem>[
    _NavItem(route: '/home', label: 'HOME', icon: Icons.home_rounded),
    _NavItem(route: '/chat', label: 'CHAT', icon: Icons.forum_rounded),
    _NavItem(
      route: '/insights',
      label: 'INSIGHTS',
      icon: Icons.grid_view_rounded,
    ),
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
    final location = GoRouterState.of(context).uri.path;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C151C).withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFDBE3ED).withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Row(
        children: _items.map((item) {
          final isSelected = location == item.route;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isSelected ? null : () => context.go(item.route),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF172C63)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected
                          ? const Color(0xFFDCE9FF)
                          : const Color(0xFF8894A3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.7,
                        color: isSelected
                            ? const Color(0xFFDCE9FF)
                            : const Color(0xFF8894A3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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

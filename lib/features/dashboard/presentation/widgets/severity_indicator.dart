import 'package:flutter/material.dart';

class SeverityIndicator extends StatelessWidget {
  final int severity;

  const SeverityIndicator({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < severity.clamp(0, 5);

        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 6),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? color
                  : const Color(0xFF31414E),
            ),
          ),
        );
      }),
    );
  }
}

Color _severityColor(int severity) {
  if (severity <= 2) {
    return const Color(0xFF7FE0A3);
  }
  if (severity == 3) {
    return const Color(0xFFFFC468);
  }
  return const Color(0xFFFF8B85);
}

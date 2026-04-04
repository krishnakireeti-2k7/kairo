import 'package:flutter/material.dart';

class SeveritySlider extends StatelessWidget {
  final int value;
  final ValueChanged<double> onChanged;

  const SeveritySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF182129),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFDBE3ED).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Severity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5F7FA),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Drag to indicate intensity',
                      style: TextStyle(fontSize: 13, color: Color(0xFFBCC5D2)),
                    ),
                  ],
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 42,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFAED0FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              inactiveTrackColor: const Color(0xFF28333D),
              activeTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFAED0FF).withValues(alpha: 0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF7FDDE0),
                    Color(0xFFB8A7F3),
                    Color(0xFFFFA8A4),
                  ],
                ).createShader(bounds);
              },
              child: Slider(
                value: value.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$value',
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MILD',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Color(0xFF8D97A4),
                ),
              ),
              Text(
                'MODERATE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Color(0xFF8D97A4),
                ),
              ),
              Text(
                'SEVERE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Color(0xFF8D97A4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

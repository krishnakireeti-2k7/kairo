import 'package:flutter/material.dart';
import 'package:kairo/features/dashboard/presentation/providers/timeline_provider.dart';

class TimelineSummaryWidget extends StatelessWidget {
  final TimelineSummary summary;

  const TimelineSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF182129),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDBE3ED).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary.dateRangeLabel} summary',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 14),
          _SummaryLine(
            label: 'Most frequent',
            value: summary.mostFrequentLabel,
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: 'Avg severity',
            value: summary.averageSeverityLabel,
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: 'Trend',
            value: summary.trendLabel,
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(
            Icons.circle,
            size: 8,
            color: Color(0xFF84E3E6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFFC4CBD6),
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Color(0xFFE8F2FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kairo/features/reports/domain/models/report_model.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onOpen;
  final VoidCallback onDownload;

  const ReportCard({
    super.key,
    required this.report,
    required this.onOpen,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Health Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(report.createdAt),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB9C4D1),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: onOpen,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8F2FF),
                  side: BorderSide(
                    color: const Color(0xFFDBE3ED).withValues(alpha: 0.10),
                  ),
                ),
                child: const Text('Open'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onDownload,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2469AE),
                  foregroundColor: const Color(0xFFE8F2FF),
                ),
                child: const Text('Download'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/${date.year} • $hour:$minute $suffix';
  }
}

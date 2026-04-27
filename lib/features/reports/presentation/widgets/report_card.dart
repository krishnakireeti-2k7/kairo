import 'package:flutter/material.dart';
import 'package:kairo/features/reports/domain/models/report_model.dart';
import 'package:kairo/features/reports/presentation/widgets/report_actions_menu.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onToggleStar;
  final VoidCallback onShare;
  final bool isStarBusy;

  const ReportCard({
    super.key,
    required this.report,
    required this.onOpen,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
    required this.onToggleStar,
    required this.onShare,
    this.isStarBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(report.id),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A252D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFDAE7F2).withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  scale: report.isStarred ? 1 : 0.94,
                  child: IconButton(
                    tooltip: report.isStarred ? 'Unstar' : 'Star',
                    onPressed: isStarBusy ? null : onToggleStar,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        report.isStarred
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        key: ValueKey(report.isStarred),
                        color: report.isStarred
                            ? const Color(0xFFFFD166)
                            : const Color(0xFF91A0AE),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onRename,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF7FAFC),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(report.createdAt),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9BAAB8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ReportActionsMenu(
                  isStarred: report.isStarred,
                  onSelected: (action) {
                    switch (action) {
                      case ReportAction.rename:
                        onRename();
                      case ReportAction.delete:
                        onDelete();
                      case ReportAction.toggleStar:
                        onToggleStar();
                      case ReportAction.share:
                        onShare();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD7E7F7),
                      side: BorderSide(
                        color: const Color(0xFFDBE3ED).withValues(alpha: 0.14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2A75B8),
                      foregroundColor: const Color(0xFFF2F8FF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

import 'package:flutter/material.dart';

enum ReportAction { rename, delete, toggleStar, share }

class ReportActionsMenu extends StatelessWidget {
  const ReportActionsMenu({
    super.key,
    required this.isStarred,
    required this.onSelected,
  });

  final bool isStarred;
  final ValueChanged<ReportAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ReportAction>(
      tooltip: 'Report actions',
      icon: const Icon(Icons.more_horiz_rounded),
      color: const Color(0xFF1B2730),
      surfaceTintColor: Colors.transparent,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: ReportAction.rename,
            child: _ReportMenuItem(icon: Icons.edit_outlined, label: 'Rename'),
          ),
          PopupMenuItem(
            value: ReportAction.toggleStar,
            child: _ReportMenuItem(
              icon: isStarred ? Icons.star_rounded : Icons.star_border_rounded,
              label: isStarred ? 'Unstar' : 'Star',
            ),
          ),
          const PopupMenuItem(
            value: ReportAction.share,
            child: _ReportMenuItem(
              icon: Icons.ios_share_outlined,
              label: 'Share',
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: ReportAction.delete,
            child: _ReportMenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: Color(0xFFFFB4AB),
            ),
          ),
        ];
      },
    );
  }
}

class _ReportMenuItem extends StatelessWidget {
  const _ReportMenuItem({
    required this.icon,
    required this.label,
    this.color = const Color(0xFFE5ECF4),
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

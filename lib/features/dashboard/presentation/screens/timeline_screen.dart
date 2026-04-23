import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/features/dashboard/presentation/providers/timeline_provider.dart';
import 'package:kairo/features/logs/domain/models/log_model.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timelineProvider.notifier).loadLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);
    final filteredLogs = state.filteredLogs;
    final groupedLogs = _groupLogs(filteredLogs);

    return Scaffold(
      backgroundColor: const Color(0xFF09131A),
      appBar: AppBar(title: const Text('Timeline')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF79D9E2),
          backgroundColor: const Color(0xFF162129),
          onRefresh: () => ref.read(timelineProvider.notifier).loadLogs(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _HeaderCard(),
                    const SizedBox(height: 16),
                    _SearchField(
                      controller: _searchController,
                      onChanged: ref.read(timelineProvider.notifier).setSearchQuery,
                    ),
                    const SizedBox(height: 14),
                    _FilterBar(
                      selected: state.timeFilter,
                      onSelected: ref.read(timelineProvider.notifier).setTimeFilter,
                    ),
                    const SizedBox(height: 18),
                    if (state.isLoading)
                      const _LoadingCard()
                    else if (state.errorMessage != null)
                      _ErrorCard(
                        message: state.errorMessage!,
                        onRetry: () => ref.read(timelineProvider.notifier).loadLogs(),
                      )
                    else if (filteredLogs.isEmpty)
                      const _EmptyStateCard()
                    else
                      ...groupedLogs.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _TimelineSection(
                            title: entry.key,
                            logs: entry.value,
                          ),
                        );
                      }),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symptom Timeline',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Explore symptom patterns over time with search and date filters.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFFC4CBD6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Color(0xFFF5F7FA)),
        decoration: const InputDecoration(
          icon: Icon(Icons.search_rounded, color: Color(0xFF84E3E6)),
          hintText: 'Search symptoms',
          hintStyle: TextStyle(color: Color(0xFF8E99A7)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TimelineTimeFilter selected;
  final ValueChanged<TimelineTimeFilter> onSelected;

  const _FilterBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: TimelineTimeFilter.values.map((filter) {
          final isSelected = filter == selected;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFFE8F2FF)
                    : const Color(0xFFB9C4D1),
                fontWeight: FontWeight.w600,
              ),
              selectedColor: const Color(0xFF2469AE),
              backgroundColor: const Color(0xFF182129),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF2D82D4)
                      : const Color(0xFFDBE3ED).withValues(alpha: 0.05),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final String title;
  final List<LogModel> logs;

  const _TimelineSection({
    required this.title,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF84E3E6),
            ),
          ),
        ),
        ...logs.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key == logs.length - 1 ? 0 : 14),
            child: _TimelineCard(log: entry.value),
          );
        }),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final LogModel log;

  const _TimelineCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(log.severity);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: severityColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: severityColor.withValues(alpha: 0.36),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            Container(
              width: 2,
              height: 132,
              margin: const EdgeInsets.only(top: 8),
              color: const Color(0xFF24323C),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (log.symptoms.isEmpty
                                ? const ['No symptoms']
                                : log.symptoms)
                            .map((symptom) => _SymptomChip(label: symptom))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatTimestamp(log.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA7B0BD),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${log.severity}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: severityColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _severityLabel(log.severity),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: severityColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Logged ${_timeAgo(log.timestamp)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB9C4D1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (log.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    log.notes,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFFD5DCE6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;

  const _SymptomChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF134D87),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E78C6)),
      ),
      child: Text(
        _titleCase(label),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFAED0FF),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: _panelDecoration(),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF79D9E2)),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFD2CC),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFFFFB4AB),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2469AE),
              foregroundColor: const Color(0xFFE8F2FF),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No logs found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start logging symptoms to unlock timeline patterns and trend review.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFFC4CBD6),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, List<LogModel>> _groupLogs(List<LogModel> logs) {
  final grouped = <String, List<LogModel>>{
    'Today': <LogModel>[],
    'Yesterday': <LogModel>[],
    'Older': <LogModel>[],
  };

  for (final log in logs) {
    final label = _dayLabel(log.timestamp);
    grouped[label]!.add(log);
  }

  grouped.removeWhere((_, value) => value.isEmpty);
  return grouped;
}

String _dayLabel(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final difference = today.difference(date).inDays;

  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  return 'Older';
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF182129),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFDBE3ED).withValues(alpha: 0.05)),
  );
}

Color _severityColor(int severity) {
  if (severity <= 3) {
    return const Color(0xFF7FE0E5);
  }
  if (severity <= 6) {
    return const Color(0xFFFFC468);
  }
  return const Color(0xFFFF8B85);
}

String _severityLabel(int severity) {
  if (severity <= 3) {
    return 'Low severity';
  }
  if (severity <= 6) {
    return 'Medium severity';
  }
  return 'High severity';
}

String _formatTimestamp(DateTime timestamp) {
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final suffix = timestamp.hour >= 12 ? 'PM' : 'AM';
  final day = timestamp.day.toString().padLeft(2, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  return '$day/$month/${timestamp.year} • $hour:$minute $suffix';
}

String _timeAgo(DateTime timestamp) {
  final difference = DateTime.now().difference(timestamp);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  return '${difference.inDays}d ago';
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1);
}

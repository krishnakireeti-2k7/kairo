import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/features/logs/domain/models/log_model.dart';
import 'package:kairo/features/logs/presentation/providers/log_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsProvider);

    return Scaffold(
      backgroundColor: _HomeColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -130,
              left: -80,
              child: _AmbientGlow(size: 280, color: Color(0x1679D9E2)),
            ),
            const Positioned(
              top: 300,
              right: -110,
              child: _AmbientGlow(size: 260, color: Color(0x148FB9F7)),
            ),
            RefreshIndicator(
              color: _HomeColors.teal,
              backgroundColor: _HomeColors.panel,
              onRefresh: () => _refresh(ref),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const _HomeHeader(),
                        const SizedBox(height: 28),
                        logsAsync.when(
                          loading: () => const _HomeSkeleton(),
                          error: (_, _) => _HomeErrorState(
                            onRetry: () => ref.invalidate(logsProvider),
                          ),
                          data: (logs) {
                            if (logs.isEmpty) {
                              return _EmptyHomeState(
                                onLog: () => context.push('/log'),
                              );
                            }

                            final snapshot = _HomeSnapshot.fromLogs(logs);
                            return _HomeContent(snapshot: snapshot);
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(logsProvider);
    await ref.read(logsProvider.future);
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.snapshot});

  final _HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LatestOverview(snapshot: snapshot),
        const SizedBox(height: 16),
        _PrimaryActions(
          onLog: () => context.push('/log'),
          onAskAi: () => context.push('/chat'),
        ),
        const SizedBox(height: 32),
        _InsightPanel(insight: snapshot.insight),
        const SizedBox(height: 20),
        _WeekPanel(snapshot: snapshot),
        const SizedBox(height: 32),
        _RecentActivity(
          logs: snapshot.recentLogs,
          onOpenTimeline: () => context.push('/timeline'),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _HomeColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(_HomeDimensions.radius),
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: _HomeColors.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kairo',
              style: TextStyle(
                color: _HomeColors.textStrong,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            _greeting(),
            style: const TextStyle(
              color: _HomeColors.textStrong,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Here is what you have recorded and what you can do next.',
          style: TextStyle(
            color: _HomeColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LatestOverview extends StatelessWidget {
  const _LatestOverview({required this.snapshot});

  final _HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final latest = snapshot.latestLog;
    final symptom = _primarySymptom(latest);
    final semanticLabel = [
      'Last recorded symptom: $symptom.',
      _relativeDateTime(latest.timestamp),
      'Severity ${latest.severity} out of 10.',
      if (latest.duration > 0) 'Duration ${_formatDuration(latest.duration)}.',
    ].join(' ');

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: _HomeColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    snapshot.hasLogsThisWeek
                        ? 'Last recorded this week'
                        : 'Last recorded',
                    style: const TextStyle(
                      color: _HomeColors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                symptom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomeColors.textStrong,
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _relativeDateTime(latest.timestamp),
                style: const TextStyle(
                  color: _HomeColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FactPill(
                    icon: Icons.speed_rounded,
                    label: 'Severity ${latest.severity} of 10',
                  ),
                  if (latest.duration > 0)
                    _FactPill(
                      icon: Icons.schedule_rounded,
                      label: _formatDuration(latest.duration),
                    ),
                ],
              ),
              if (!snapshot.hasLogsThisWeek) ...[
                const SizedBox(height: 16),
                const Divider(color: _HomeColors.divider, height: 1),
                const SizedBox(height: 14),
                const Text(
                  'No episodes have been recorded in the last 7 days.',
                  style: TextStyle(
                    color: _HomeColors.textMuted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FactPill extends StatelessWidget {
  const _FactPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _HomeColors.surface,
        borderRadius: BorderRadius.circular(_HomeDimensions.radius),
        border: Border.all(color: _HomeColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _HomeColors.blue),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: _HomeColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.onLog, required this.onAskAi});

  final VoidCallback onLog;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final stackButtons = MediaQuery.textScalerOf(context).scale(15) > 19;

    final logButton = FilledButton.icon(
      onPressed: onLog,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Log New Symptom'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: _HomeColors.action,
        foregroundColor: _HomeColors.actionText,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_HomeDimensions.radius),
        ),
      ),
    );
    final aiButton = OutlinedButton.icon(
      onPressed: onAskAi,
      icon: const Icon(Icons.forum_outlined),
      label: const Text('Ask AI'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: _HomeColors.textStrong,
        side: const BorderSide(color: _HomeColors.outline),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_HomeDimensions.radius),
        ),
      ),
    );

    if (stackButtons) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: logButton),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: aiButton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: logButton),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: aiButton),
      ],
    );
  }
}

class _InsightPanel extends StatefulWidget {
  const _InsightPanel({required this.insight});

  final _HomeInsight insight;

  @override
  State<_InsightPanel> createState() => _InsightPanelState();
}

class _InsightPanelState extends State<_InsightPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(
        borderColor: _HomeColors.blue.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 19,
                color: _HomeColors.blue,
              ),
              SizedBox(width: 9),
              Text(
                "Today's insight",
                style: TextStyle(
                  color: _HomeColors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              widget.insight.title,
              style: const TextStyle(
                color: _HomeColors.textStrong,
                fontSize: 20,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.insight.summary,
            style: const TextStyle(
              color: _HomeColors.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            button: true,
            expanded: _expanded,
            label: _expanded
                ? 'Hide insight evidence'
                : 'Show why this insight appears',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(_HomeDimensions.radius),
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _expanded
                                ? 'Hide explanation'
                                : 'Why am I seeing this?',
                            style: const TextStyle(
                              color: _HomeColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _HomeColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      children: widget.insight.evidence
                          .map((item) => _EvidenceRow(text: item))
                          .toList(growable: false),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 17,
              color: _HomeColors.teal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _HomeColors.text,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPanel extends StatelessWidget {
  const _WeekPanel({required this.snapshot});

  final _HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _WeekStatData(
        label: 'Episodes',
        value: '${snapshot.weekLogs.length}',
        semanticValue: '${snapshot.weekLogs.length} episodes',
      ),
      _WeekStatData(
        label: 'Avg severity',
        value: snapshot.averageSeverity == null
            ? '--'
            : snapshot.averageSeverity!.toStringAsFixed(1),
        semanticValue: snapshot.averageSeverity == null
            ? 'No average severity'
            : 'Average severity ${snapshot.averageSeverity!.toStringAsFixed(1)} out of 10',
      ),
      _WeekStatData(
        label: 'Avg duration',
        value: snapshot.averageDuration == null
            ? '--'
            : _formatDuration(snapshot.averageDuration!.round()),
        semanticValue: snapshot.averageDuration == null
            ? 'No average duration'
            : 'Average duration ${_formatDuration(snapshot.averageDuration!.round())}',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This week',
            style: TextStyle(
              color: _HomeColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Based on entries from the last 7 days.',
            style: TextStyle(color: _HomeColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final useRows =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18;
              if (useRows) {
                return Column(
                  children: stats
                      .map((stat) => _WeekStatRow(data: stat))
                      .toList(growable: false),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: stats
                    .asMap()
                    .entries
                    .map((entry) {
                      return Expanded(
                        child: Container(
                          padding: EdgeInsets.only(
                            left: entry.key == 0 ? 0 : 14,
                            right: entry.key == stats.length - 1 ? 0 : 14,
                          ),
                          decoration: entry.key == stats.length - 1
                              ? null
                              : const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: _HomeColors.divider,
                                    ),
                                  ),
                                ),
                          child: _WeekStat(data: entry.value),
                        ),
                      );
                    })
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekStatData {
  const _WeekStatData({
    required this.label,
    required this.value,
    required this.semanticValue,
  });

  final String label;
  final String value;
  final String semanticValue;
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({required this.data});

  final _WeekStatData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${data.label}: ${data.semanticValue}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomeColors.textStrong,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data.label,
              style: const TextStyle(
                color: _HomeColors.textMuted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStatRow extends StatelessWidget {
  const _WeekStatRow({required this.data});

  final _WeekStatData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${data.label}: ${data.semanticValue}',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _HomeColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: const TextStyle(
                    color: _HomeColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                data.value,
                style: const TextStyle(
                  color: _HomeColors.textStrong,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.logs, required this.onOpenTimeline});

  final List<LogModel> logs;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent activity',
          style: TextStyle(
            color: _HomeColors.textStrong,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'A quick reminder of your latest entries.',
          style: TextStyle(color: _HomeColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: _panelDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: logs
                .asMap()
                .entries
                .map((entry) {
                  return _RecentActivityRow(
                    log: entry.value,
                    showDivider: entry.key != logs.length - 1,
                    onTap: onOpenTimeline,
                  );
                })
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onOpenTimeline,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('View full history'),
            style: TextButton.styleFrom(
              foregroundColor: _HomeColors.teal,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({
    required this.log,
    required this.showDivider,
    required this.onTap,
  });

  final LogModel log;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final symptom = _primarySymptom(log);
    return Semantics(
      button: true,
      label:
          '$symptom, ${_relativeDateTime(log.timestamp)}, severity ${log.severity} out of 10. Open full history.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minHeight: 76),
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: showDivider
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _HomeColors.divider),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _HomeColors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        _HomeDimensions.radius,
                      ),
                    ),
                    child: const Icon(
                      Icons.notes_rounded,
                      color: _HomeColors.blue,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symptom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _HomeColors.textStrong,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _relativeDateTime(log.timestamp),
                          style: const TextStyle(
                            color: _HomeColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Severity ${log.severity}',
                    style: const TextStyle(
                      color: _HomeColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _HomeColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState({required this.onLog});

  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _HomeColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(_HomeDimensions.radius),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: _HomeColors.teal,
              size: 27,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start building your symptom history',
            style: TextStyle(
              color: _HomeColors.textStrong,
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Consistent entries can help you notice patterns and prepare clearer information for future appointments.',
            style: TextStyle(
              color: _HomeColors.textMuted,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log First Symptom'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _HomeColors.action,
                foregroundColor: _HomeColors.actionText,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_HomeDimensions.radius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: _HomeColors.textMuted,
            size: 30,
          ),
          const SizedBox(height: 18),
          const Text(
            "We couldn't load your health history",
            style: TextStyle(
              color: _HomeColors.textStrong,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection and try again. Your saved entries have not been changed.',
            style: TextStyle(
              color: _HomeColors.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 50),
              foregroundColor: _HomeColors.textStrong,
              side: const BorderSide(color: _HomeColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_HomeDimensions.radius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatefulWidget {
  const _HomeSkeleton();

  @override
  State<_HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<_HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.55 + (_controller.value * 0.25),
          child: child,
        );
      },
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBlock(height: 190),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 54)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBlock(height: 54)),
            ],
          ),
          SizedBox(height: 32),
          _SkeletonBlock(height: 180),
          SizedBox(height: 20),
          _SkeletonBlock(height: 150),
          SizedBox(height: 32),
          _SkeletonLine(width: 140, height: 20),
          SizedBox(height: 14),
          _SkeletonBlock(height: 150),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: _HomeColors.panel,
        borderRadius: BorderRadius.circular(_HomeDimensions.radius),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _HomeColors.panel,
        borderRadius: BorderRadius.circular(_HomeDimensions.radius),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, Colors.transparent]),
          ),
        ),
      ),
    );
  }
}

class _HomeSnapshot {
  const _HomeSnapshot({
    required this.latestLog,
    required this.weekLogs,
    required this.recentLogs,
    required this.averageSeverity,
    required this.averageDuration,
    required this.insight,
  });

  final LogModel latestLog;
  final List<LogModel> weekLogs;
  final List<LogModel> recentLogs;
  final double? averageSeverity;
  final double? averageDuration;
  final _HomeInsight insight;

  bool get hasLogsThisWeek => weekLogs.isNotEmpty;

  factory _HomeSnapshot.fromLogs(List<LogModel> source) {
    final logs = [...source]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final weekLogs = logs
        .where((log) => !log.timestamp.isBefore(cutoff))
        .toList(growable: false);
    final durations = weekLogs
        .where((log) => log.duration > 0)
        .map((log) => log.duration)
        .toList(growable: false);
    final averageSeverity = weekLogs.isEmpty
        ? null
        : weekLogs.fold<int>(0, (sum, log) => sum + log.severity) /
              weekLogs.length;
    final averageDuration = durations.isEmpty
        ? null
        : durations.reduce((a, b) => a + b) / durations.length;

    return _HomeSnapshot(
      latestLog: logs.first,
      weekLogs: weekLogs,
      recentLogs: logs.take(3).toList(growable: false),
      averageSeverity: averageSeverity,
      averageDuration: averageDuration,
      insight: _buildInsight(weekLogs, logs.first),
    );
  }
}

class _HomeInsight {
  const _HomeInsight({
    required this.title,
    required this.summary,
    required this.evidence,
  });

  final String title;
  final String summary;
  final List<String> evidence;
}

_HomeInsight _buildInsight(List<LogModel> weekLogs, LogModel latestLog) {
  if (weekLogs.isEmpty) {
    return _HomeInsight(
      title: 'A new entry will make this overview current',
      summary:
          'Kairo does not use older history to infer how you are feeling today.',
      evidence: [
        '0 entries were recorded in the last 7 days.',
        'Your latest entry was ${_relativeDateTime(latestLog.timestamp).toLowerCase()}.',
      ],
    );
  }

  final symptomCounts = <String, int>{};
  final displayNames = <String, String>{};
  for (final log in weekLogs) {
    for (final symptom in log.symptoms) {
      final normalized = symptom.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      symptomCounts[normalized] = (symptomCounts[normalized] ?? 0) + 1;
      displayNames.putIfAbsent(normalized, () => _titleCase(symptom.trim()));
    }
  }

  if (symptomCounts.isNotEmpty) {
    final top = symptomCounts.entries.reduce((a, b) {
      if (a.value != b.value) return a.value > b.value ? a : b;
      return a.key.compareTo(b.key) <= 0 ? a : b;
    });
    final relevantLogs = weekLogs
        .where((log) {
          return log.symptoms.any(
            (symptom) => symptom.trim().toLowerCase() == top.key,
          );
        })
        .toList(growable: false);
    final averageSeverity =
        relevantLogs.fold<int>(0, (sum, log) => sum + log.severity) /
        relevantLogs.length;

    if (top.value >= 2) {
      final name = displayNames[top.key] ?? _titleCase(top.key);
      return _HomeInsight(
        title: '$name appeared in ${top.value} entries this week',
        summary:
            'This is a frequency observation from your entries, not a diagnosis or prediction.',
        evidence: [
          '${top.value} of ${weekLogs.length} entries included $name.',
          'Those entries had an average severity of ${averageSeverity.toStringAsFixed(1)} out of 10.',
          'Only entries from the last 7 days were considered.',
        ],
      );
    }
  }

  final averageSeverity =
      weekLogs.fold<int>(0, (sum, log) => sum + log.severity) / weekLogs.length;
  return _HomeInsight(
    title:
        '${weekLogs.length} ${weekLogs.length == 1 ? 'episode' : 'episodes'} recorded this week',
    summary:
        'No symptom repeated enough in this window to highlight a frequency pattern.',
    evidence: [
      '${weekLogs.length} ${weekLogs.length == 1 ? 'entry was' : 'entries were'} recorded in the last 7 days.',
      'Average severity was ${averageSeverity.toStringAsFixed(1)} out of 10.',
    ],
  );
}

BoxDecoration _panelDecoration({Color borderColor = _HomeColors.divider}) {
  return BoxDecoration(
    color: _HomeColors.panel,
    borderRadius: BorderRadius.circular(_HomeDimensions.radius),
    border: Border.all(color: borderColor),
  );
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _primarySymptom(LogModel log) {
  final symptoms = log.symptoms
      .map((symptom) => symptom.trim())
      .where((symptom) => symptom.isNotEmpty)
      .toList(growable: false);
  if (symptoms.isEmpty) return 'Symptom entry';

  final first = _titleCase(symptoms.first);
  return symptoms.length == 1 ? first : '$first +${symptoms.length - 1}';
}

String _relativeDateTime(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  final difference = today.difference(date).inDays;
  final time = _formatTime(value);

  if (difference == 0) return 'Today at $time';
  if (difference == 1) return 'Yesterday at $time';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final year = value.year == now.year ? '' : ' ${value.year}';
  return '${value.day} ${months[value.month - 1]}$year at $time';
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}m';
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

abstract final class _HomeDimensions {
  static const double radius = 16;
}

abstract final class _HomeColors {
  static const Color background = Color(0xFF09131A);
  static const Color panel = Color(0xFF17222A);
  static const Color surface = Color(0xFF111B22);
  static const Color divider = Color(0xFF26343E);
  static const Color outline = Color(0xFF3B4A55);
  static const Color textStrong = Color(0xFFF2F6FA);
  static const Color text = Color(0xFFD4DCE5);
  static const Color textMuted = Color(0xFF9CA9B6);
  static const Color teal = Color(0xFF79D9E2);
  static const Color blue = Color(0xFFA9CFFF);
  static const Color action = Color(0xFF7FCFEF);
  static const Color actionText = Color(0xFF082235);
}

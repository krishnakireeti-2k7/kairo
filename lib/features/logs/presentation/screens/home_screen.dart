import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/features/auth/presentation/providers/auth_provider.dart';
import 'package:kairo/features/logs/domain/models/log_model.dart';
import 'package:kairo/features/logs/presentation/providers/log_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsProvider);
    final logs = logsAsync.asData?.value ?? const <LogModel>[];
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF09131A),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -20,
              child: _AmbientGlow(
                size: 250,
                color: const Color(0xFF79D9E2).withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: -50,
              top: 250,
              child: _AmbientGlow(
                size: 220,
                color: const Color(0xFF8FB9F7).withValues(alpha: 0.10),
              ),
            ),
            RefreshIndicator(
              color: const Color(0xFF79D9E2),
              backgroundColor: const Color(0xFF162129),
              onRefresh: () async {
                ref.invalidate(logsProvider);
                await ref.read(logsProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Header ──────────────────────────────────────────
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF18B6B),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '🧑🏻‍⚕️',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Kairo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF7FAFF),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () async => authNotifier.signOut(),
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFD7E3F3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // ── Greeting + Headline ──────────────────────────────
                        Text(
                          _greetingLabel(),
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.8,
                            color: Color(0xFF84E3E6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _headline(logs),
                          style: const TextStyle(
                            fontSize: 58,
                            height: 0.9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC9DEFF),
                            letterSpacing: -2.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _summary(logs),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color(0xFFCBD2DD),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── This Week card ───────────────────────────────────
                        _ThisWeekCard(logs: logs),
                        const SizedBox(height: 16),

                        // ── Top Symptom + Pattern ────────────────────────────
                        _TopSymptomCard(logs: logs),
                        const SizedBox(height: 16),

                        // ── Bring This Up card ───────────────────────────────
                        _BringThisUpCard(logs: logs),
                        const SizedBox(height: 28),

                        // ── Recent Logs ──────────────────────────────────────
                        const Text(
                          'Recent Logs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF5F7FA),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LogsSection(logsAsync: logsAsync),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 16,
              bottom: 24,
              child: FloatingActionButton(
                onPressed: () => context.push('/log'),
                backgroundColor: const Color(0xFF8ED7F7),
                child: const Icon(Icons.add_rounded, color: Color(0xFF07243B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── This Week Card ────────────────────────────────────────────────────────────

class _ThisWeekCard extends StatelessWidget {
  final List<LogModel> logs;

  const _ThisWeekCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final threshold = DateTime.now().subtract(const Duration(days: 7));
    final weekLogs = logs.where((l) => l.timestamp.isAfter(threshold)).toList();
    final totalLogs = weekLogs.length;
    final avgSeverity = totalLogs == 0
        ? null
        : weekLogs.map((l) => l.severity).reduce((a, b) => a + b) / totalLogs;
    final avgDuration = totalLogs == 0
        ? null
        : weekLogs.map((l) => l.duration).reduce((a, b) => a + b) / totalLogs;

    // Find most common day
    String? peakDay;
    if (weekLogs.isNotEmpty) {
      final dayCounts = <int, int>{};
      for (final log in weekLogs) {
        dayCounts[log.timestamp.weekday] =
            (dayCounts[log.timestamp.weekday] ?? 0) + 1;
      }
      final maxEntry = dayCounts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      peakDay = _weekdayName(maxEntry.key);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF84E3E6).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Color(0xFF84E3E6),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'THIS WEEK',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Color(0xFF84E3E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (totalLogs == 0)
            const Text(
              'No entries in the last 7 days.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFA4AFBD),
                height: 1.5,
              ),
            )
          else ...[
            _WeekStatRow(
              label: 'Episodes logged',
              value: '$totalLogs',
              accent: const Color(0xFFC9DEFF),
            ),
            const SizedBox(height: 12),
            _WeekStatRow(
              label: 'Average severity',
              value: '${avgSeverity!.toStringAsFixed(1)} / 10',
              accent: _severityColor(avgSeverity.round()),
            ),
            if (avgDuration != null) ...[
              const SizedBox(height: 12),
              _WeekStatRow(
                label: 'Average duration',
                value: '${avgDuration.round()} mins',
                accent: const Color(0xFFD7B7FF),
              ),
            ],
            if (peakDay != null) ...[
              const SizedBox(height: 12),
              _WeekStatRow(
                label: 'Most episodes on',
                value: peakDay,
                accent: const Color(0xFFFFA8A4),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WeekStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _WeekStatRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFFA4AFBD)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }
}

// ── Top Symptom Card ──────────────────────────────────────────────────────────

class _TopSymptomCard extends StatelessWidget {
  final List<LogModel> logs;

  const _TopSymptomCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    // Count symptom frequencies
    final freq = <String, int>{};
    for (final log in logs) {
      for (final s in log.symptoms) {
        freq[s] = (freq[s] ?? 0) + 1;
      }
    }
    if (freq.isEmpty) return const SizedBox.shrink();

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final topName = top.key.isEmpty
        ? top.key
        : top.key[0].toUpperCase() + top.key.substring(1);
    final count = top.value;

    // Average severity for that symptom
    final relevantLogs = logs
        .where((l) => l.symptoms.contains(top.key))
        .toList();
    final avgSev = relevantLogs.isEmpty
        ? 0.0
        : relevantLogs.map((l) => l.severity).reduce((a, b) => a + b) /
              relevantLogs.length;

    // Average duration for that symptom
    final avgDur = relevantLogs.isEmpty
        ? 0.0
        : relevantLogs.map((l) => l.duration).reduce((a, b) => a + b) /
              relevantLogs.length;

    // Time of day pattern
    final timePattern = _timeOfDayPattern(relevantLogs);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7B7FF).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 14,
                  color: Color(0xFFD7B7FF),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TOP SYMPTOM',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Color(0xFFD7B7FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                topName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF5F7FA),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '$count ${count == 1 ? 'episode' : 'episodes'} total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFA4AFBD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Mini stat row
          Row(
            children: [
              _MiniStat(
                label: 'Avg severity',
                value: avgSev.toStringAsFixed(1),
                color: _severityColor(avgSev.round()),
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Avg duration',
                value: '${avgDur.round()} min',
                color: const Color(0xFFD7B7FF),
              ),
              if (timePattern != null) ...[
                const SizedBox(width: 16),
                _MiniStat(
                  label: 'Often in',
                  value: timePattern,
                  color: const Color(0xFF84E3E6),
                ),
              ],
            ],
          ),
          if (sorted.length > 1) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1E2D38), height: 1),
            const SizedBox(height: 14),
            const Text(
              'Other symptoms',
              style: TextStyle(fontSize: 12, color: Color(0xFF7A8A99)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sorted.skip(1).take(4).map((e) {
                final name = e.key.isEmpty
                    ? e.key
                    : e.key[0].toUpperCase() + e.key.substring(1);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF134D87).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2E78C6).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '$name · ${e.value}x',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAED0FF),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF7A8A99)),
        ),
      ],
    );
  }
}

// ── Bring This Up Card ────────────────────────────────────────────────────────

class _BringThisUpCard extends StatelessWidget {
  final List<LogModel> logs;

  const _BringThisUpCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final prompts = _generatePrompts(logs);
    if (prompts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF182129),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2469AE).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2469AE).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: Color(0xFF8FB9F7),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'BRING THIS UP',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Color(0xFF8FB9F7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Mention to your doctor',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 14),
          ...prompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: Color(0xFF8FB9F7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFFCBD2DD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logs Section ──────────────────────────────────────────────────────────────

class _LogsSection extends StatelessWidget {
  final AsyncValue<List<LogModel>> logsAsync;

  const _LogsSection({required this.logsAsync});

  @override
  Widget build(BuildContext context) {
    return logsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: _panelDecoration(),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF79D9E2)),
          ),
        ),
      ),
      error: (error, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _panelDecoration(),
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 15),
        ),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'No logs yet',
                  style: TextStyle(
                    color: Color(0xFFE5EBF4),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap the + button below to record your first symptom entry.',
                  style: TextStyle(
                    color: Color(0xFFA4AFBD),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: _panelDecoration(),
          child: ListView.builder(
            itemCount: logs.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == logs.length - 1 ? 0 : 16,
                ),
                child: _LogListItem(log: logs[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class _LogListItem extends StatelessWidget {
  final LogModel log;

  const _LogListItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _severityColor(log.severity).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              '${log.severity}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _severityColor(log.severity),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: log.symptoms.isEmpty
                        ? const Text(
                            'No symptoms',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF5F7FA),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: log.symptoms.map((s) {
                              final display = s.isEmpty
                                  ? s
                                  : s[0].toUpperCase() + s.substring(1);
                              return Chip(
                                label: Text(
                                  display,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFAED0FF),
                                  ),
                                ),
                                backgroundColor: const Color(0xFF134D87),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Color(0xFF2E78C6),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(log.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA7B0BD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Severity ${log.severity} · ${log.duration} mins',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF87E6EF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (log.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  log.notes,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFFD5DCE6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF182129),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFDBE3ED).withValues(alpha: 0.05)),
  );
}

String _greetingLabel() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'MORNING OVERVIEW';
  if (hour < 17) return 'AFTERNOON OVERVIEW';
  return 'EVENING OVERVIEW';
}

String _headline(List<LogModel> logs) {
  if (logs.isEmpty) return 'Ready\nTo Log';
  final avg = logs.map((l) => l.severity).reduce((a, b) => a + b) / logs.length;
  if (avg <= 3) return 'Stable\n& Calm';
  if (avg <= 6) return 'Watchful\n& Aware';
  return 'Take It\nEasy';
}

String _summary(List<LogModel> logs) {
  if (logs.isEmpty) {
    return 'Start tracking symptoms to build a clearer picture of patterns, triggers, and recovery trends.';
  }
  final latest = logs.first;
  return 'Your recent entries suggest ${_severityLabel(latest.severity).toLowerCase()} symptoms. Keep logging to strengthen trend visibility for care decisions.';
}

List<String> _generatePrompts(List<LogModel> logs) {
  if (logs.isEmpty) return [];
  final prompts = <String>[];

  // Frequency prompt
  final freq = <String, int>{};
  for (final log in logs) {
    for (final s in log.symptoms) {
      freq[s] = (freq[s] ?? 0) + 1;
    }
  }
  if (freq.isNotEmpty) {
    final top = freq.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final name = top.key.isEmpty
        ? top.key
        : top.key[0].toUpperCase() + top.key.substring(1);
    if (top.value >= 2) {
      prompts.add(
        '$name has occurred ${top.value} times across your logs — worth discussing if it feels recurring.',
      );
    }
  }

  // Long duration prompt
  final longDuration = logs
      .where((l) => l.duration >= 180 && l.symptoms.isNotEmpty)
      .toList();
  if (longDuration.length >= 2) {
    final symptom = longDuration.first.symptoms.first;
    final name = symptom.isEmpty
        ? symptom
        : symptom[0].toUpperCase() + symptom.substring(1);
    prompts.add(
      '$name episodes lasting 3+ hours have appeared ${longDuration.length} times — duration patterns can be clinically significant.',
    );
  }

  // High severity prompt
  final highSev = logs.where((l) => l.severity >= 7).toList();
  if (highSev.length >= 2) {
    prompts.add(
      'You\'ve logged ${highSev.length} high-severity episodes (7+). Bring these dates and any notes to your appointment.',
    );
  }

  // Recent spike prompt
  final recent = logs
      .where(
        (l) => l.timestamp.isAfter(
          DateTime.now().subtract(const Duration(days: 7)),
        ),
      )
      .toList();
  final older = logs
      .where(
        (l) =>
            l.timestamp.isBefore(
              DateTime.now().subtract(const Duration(days: 7)),
            ) &&
            l.timestamp.isAfter(
              DateTime.now().subtract(const Duration(days: 14)),
            ),
      )
      .toList();
  if (recent.length > older.length + 1 && older.isNotEmpty) {
    prompts.add(
      'Your symptom frequency has increased this week compared to last — a trend worth flagging.',
    );
  }

  return prompts.take(3).toList();
}

String? _timeOfDayPattern(List<LogModel> logs) {
  if (logs.length < 2) return null;
  final hours = logs.map((l) => l.timestamp.hour).toList();
  final avg = hours.reduce((a, b) => a + b) / hours.length;
  if (avg < 12) return 'mornings';
  if (avg < 17) return 'afternoons';
  return 'evenings';
}

String _weekdayName(int weekday) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return days[weekday - 1];
}

Color _severityColor(int severity) {
  if (severity <= 3) return const Color(0xFF7FE0E5);
  if (severity <= 6) return const Color(0xFFAED0FF);
  return const Color(0xFFFFA8A4);
}

String _severityLabel(int severity) {
  if (severity <= 3) return 'Mild';
  if (severity <= 6) return 'Moderate';
  return 'Severe';
}

String _formatDateTime(DateTime timestamp) {
  final now = DateTime.now();
  final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(date).inDays;
  if (diff == 0) return 'Today • ${_formatTime(timestamp)}';
  if (diff == 1) return 'Yesterday • ${_formatTime(timestamp)}';
  return '${timestamp.day}/${timestamp.month}/${timestamp.year} • ${_formatTime(timestamp)}';
}

String _formatTime(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${t.hour >= 12 ? 'PM' : 'AM'}';
}

String _timeAgo(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/core/widgets/app_bottom_navigation.dart';
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
    final session = Supabase.instance.client.auth.currentSession;
    print("TOKEN: ${session?.accessToken}");

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
                              onPressed: () async {
                                await authNotifier.signOut();
                              },
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFD7E3F3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'MORNING OVERVIEW',
                          style: TextStyle(
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
                        Row(
                          children: [
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.local_hospital_rounded,
                                accent: const Color(0xFF84E3E6),
                                title: 'Symptom Streak',
                                mainLine: '${_logsThisWeek(logs)}',
                                subLine: 'entries in the last 7 days',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.history_rounded,
                                accent: const Color(0xFFD7B7FF),
                                title: 'Last Logged',
                                mainLine: _lastLoggedTitle(logs),
                                subLine: _lastLoggedSubtitle(logs),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _ReadinessCard(logs: logs),
                        const SizedBox(height: 28),
                        Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Recent Logs',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF5F7FA),
                                ),
                              ),
                            ),
                            Text(
                              'Most Recent',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFA4AFBD),
                              ),
                            ),
                          ],
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
              bottom: 94,
              child: FloatingActionButton(
                onPressed: () => context.push('/log'),
                backgroundColor: const Color(0xFF8ED7F7),
                child: const Icon(Icons.add_rounded, color: Color(0xFF07243B)),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }
}

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
            padding: const EdgeInsets.all(20),
            decoration: _panelDecoration(),
            child: const Text(
              'No logs yet',
              style: TextStyle(
                color: Color(0xFFE5EBF4),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
              final log = logs[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == logs.length - 1 ? 0 : 16,
                ),
                child: _LogListItem(log: log),
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
                              String display(String str) {
                                if (str.isEmpty) return str;
                                return str[0].toUpperCase() + str.substring(1);
                              }
                              return Chip(
                                label: Text(
                                  display(s),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFAED0FF),
                                  ),
                                ),
                                backgroundColor: const Color(0xFF134D87),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Color(0xFF2E78C6)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                'Severity: ${log.severity}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF87E6EF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(log.timestamp),
                style: const TextStyle(fontSize: 12, color: Color(0xFFA7B0BD)),
              ),

              if (log.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String mainLine;
  final String subLine;

  const _InfoCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.mainLine,
    required this.subLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mainLine,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Color(0xFFC4CBD6)),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final List<LogModel> logs;

  const _ReadinessCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final readiness = _readiness(logs);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: readiness / 100,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFF23323A),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF79D9E2),
                  ),
                ),
                Center(
                  child: Text(
                    '$readiness%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF5F7FA),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Consultation Readiness',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            logs.isEmpty
                ? 'Start logging symptoms to build a stronger trend view for future clinical summaries.'
                : 'Your logs are organized and ready for review. Recent entries are already visible in your timeline.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFFC4CBD6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2469AE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Generate Clinical Report',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8F2FF),
              ),
            ),
          ),
        ],
      ),
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

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF182129),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFDBE3ED).withValues(alpha: 0.05)),
  );
}

String _headline(List<LogModel> logs) {
  if (logs.isEmpty) {
    return 'Ready\nTo Log';
  }

  final avgSeverity =
      logs.map((log) => log.severity).reduce((a, b) => a + b) / logs.length;
  if (avgSeverity <= 3) {
    return 'Stable\n& Calm';
  }
  if (avgSeverity <= 6) {
    return 'Watchful\n& Aware';
  }
  return 'Take It\nEasy';
}

String _summary(List<LogModel> logs) {
  if (logs.isEmpty) {
    return 'Start tracking symptoms to build a clearer picture of patterns, triggers, and recovery trends.';
  }

  final latest = logs.first;
  return 'Your recent entries suggest ${_severityLabel(latest.severity).toLowerCase()} symptoms. Keep logging to strengthen trend visibility for care decisions.';
}

int _logsThisWeek(List<LogModel> logs) {
  final threshold = DateTime.now().subtract(const Duration(days: 7));
  return logs.where((log) => log.timestamp.isAfter(threshold)).length;
}

String _lastLoggedTitle(List<LogModel> logs) {
  if (logs.isEmpty) {
    return 'No symptoms yet';
  }
  return _severityLabel(logs.first.severity);
}

String _lastLoggedSubtitle(List<LogModel> logs) {
  if (logs.isEmpty) {
    return 'Create your first entry';
  }
  return '${_timeAgo(logs.first.timestamp)} • ${logs.first.duration} mins';
}

int _readiness(List<LogModel> logs) {
  if (logs.isEmpty) {
    return 85;
  }
  final avgSeverity =
      logs.map((log) => log.severity).reduce((a, b) => a + b) / logs.length;
  final score = (100 - (avgSeverity * 8)).round().clamp(35, 96);
  return score;
}

Color _severityColor(int severity) {
  if (severity <= 3) {
    return const Color(0xFF7FE0E5);
  }
  if (severity <= 6) {
    return const Color(0xFFAED0FF);
  }
  return const Color(0xFFFFA8A4);
}

String _severityLabel(int severity) {
  if (severity <= 3) {
    return 'Mild';
  }
  if (severity <= 6) {
    return 'Moderate';
  }
  return 'Severe';
}

String _formatDateTime(DateTime timestamp) {
  final now = DateTime.now();
  final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final today = DateTime(now.year, now.month, now.day);
  final difference = today.difference(date).inDays;

  if (difference == 0) {
    return 'Today • ${_formatTime(timestamp)}';
  }
  if (difference == 1) {
    return 'Yesterday • ${_formatTime(timestamp)}';
  }
  return '${timestamp.day}/${timestamp.month}/${timestamp.year} • ${_formatTime(timestamp)}';
}

String _formatTime(DateTime timestamp) {
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final suffix = timestamp.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/features/reports/domain/models/report_model.dart';
import 'package:kairo/features/reports/presentation/providers/report_provider.dart';
import 'package:kairo/features/reports/presentation/widgets/report_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final ProviderSubscription<ReportState> _reportSubscription;
  bool _showStarredOnly = false;

  @override
  void initState() {
    super.initState();
    _reportSubscription = ref.listenManual(reportProvider, (_, next) {
      if (next.errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: const Color(0xFF7A2F36),
            ),
          );
        Future<void>.microtask(() {
          if (mounted) {
            ref.read(reportsProvider.notifier).clearError();
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reportActionsProvider).loadReports();
    });
  }

  @override
  void dispose() {
    _reportSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final starredReports = ref.watch(starredReportsProvider);
    final visibleReports = _showStarredOnly ? starredReports : state.reports;

    return Scaffold(
      backgroundColor: const Color(0xFF09131A),
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF79D9E2),
          backgroundColor: const Color(0xFF162129),
          onRefresh: () => ref.read(reportActionsProvider).loadReports(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeaderCard(
                      isGenerating: state.isGenerating,
                      onGenerate: () {
                        ref.read(reportActionsProvider).generateReport();
                      },
                    ),
                    const SizedBox(height: 14),
                    _ReportsToolbar(
                      showStarredOnly: _showStarredOnly,
                      starredCount: starredReports.length,
                      onToggleStarred: () {
                        setState(() {
                          _showStarredOnly = !_showStarredOnly;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (state.isLoading)
                      const _LoadingCard()
                    else if (visibleReports.isEmpty)
                      _EmptyReportsCard(showStarredOnly: _showStarredOnly)
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Column(
                          key: ValueKey(_showStarredOnly),
                          children: visibleReports
                              .asMap()
                              .entries
                              .map((entry) {
                                final report = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        entry.key == visibleReports.length - 1
                                        ? 0
                                        : 16,
                                  ),
                                  child: ReportCard(
                                    report: report,
                                    isStarBusy: state.pendingStarIds.contains(
                                      report.id,
                                    ),
                                    onOpen: () {
                                      if (!context.mounted) return;
                                      context.push(
                                        '/reports/pdf',
                                        extra: report.url,
                                      );
                                    },
                                    onDownload: () => launchUrl(
                                      Uri.parse(report.url),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    onRename: () => _showRenameSheet(report),
                                    onDelete: () => _confirmDelete(report),
                                    onToggleStar: () {
                                      _runAfterRouteSettles(() {
                                        ref
                                            .read(reportActionsProvider)
                                            .toggleStar(report);
                                      });
                                    },
                                    onShare: _showSharePlaceholder,
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameSheet(ReportModel report) async {
    final controller = TextEditingController(text: report.name);
    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rename report',
                style: TextStyle(
                  color: Color(0xFFF5F7FA),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: Color(0xFFF5F7FA)),
                decoration: InputDecoration(
                  hintText: 'Health Report',
                  hintStyle: const TextStyle(color: Color(0xFF7F8D9A)),
                  filled: true,
                  fillColor: const Color(0xFF1A252D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFFDAE7F2).withValues(alpha: 0.12),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF79D9E2)),
                  ),
                ),
                onSubmitted: (value) {
                  Navigator.of(context).pop(value);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD7E7F7),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(controller.text);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A75B8),
                        foregroundColor: const Color(0xFFF2F8FF),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    final trimmed = newName?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == report.name) {
      return;
    }

    ref
        .read(reportActionsProvider)
        .renameReport(reportId: report.id, name: trimmed);
  }

  Future<void> _confirmDelete(ReportModel report) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111B23),
          surfaceTintColor: Colors.transparent,
          title: const Text('Delete report?'),
          content: const Text('Are you sure you want to delete this report?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8C3D44),
                foregroundColor: const Color(0xFFFFF7F7),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await ref.read(reportActionsProvider).deleteReport(report.id);
  }

  void _runAfterRouteSettles(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        action();
      });
    });
  }

  void _showSharePlaceholder() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Sharing coming soon')));
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.isGenerating, required this.onGenerate});

  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinical Reports',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate AI-assisted PDF summaries from recent symptom history.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFFC4CBD6),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isGenerating ? null : onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2A75B8),
              foregroundColor: const Color(0xFFF2F8FF),
              minimumSize: const Size.fromHeight(48),
            ),
            child: isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE8F2FF),
                      ),
                    ),
                  )
                : const Text('Generate Report'),
          ),
        ],
      ),
    );
  }
}

class _ReportsToolbar extends StatelessWidget {
  const _ReportsToolbar({
    required this.showStarredOnly,
    required this.starredCount,
    required this.onToggleStarred,
  });

  final bool showStarredOnly;
  final int starredCount;
  final VoidCallback onToggleStarred;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            showStarredOnly ? 'Starred Reports' : 'Recent Reports',
            style: const TextStyle(
              color: Color(0xFFEAF1F8),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onToggleStarred,
          icon: Icon(
            showStarredOnly
                ? Icons.list_alt_rounded
                : Icons.star_border_rounded,
            size: 18,
          ),
          label: Text(
            showStarredOnly
                ? 'All Reports'
                : 'Starred Reports${starredCount > 0 ? ' ($starredCount)' : ''}',
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF9EB2C4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: _panelDecoration(),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF79D9E2)),
        ),
      ),
    );
  }
}

class _EmptyReportsCard extends StatelessWidget {
  const _EmptyReportsCard({required this.showStarredOnly});

  final bool showStarredOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showStarredOnly ? 'No starred reports' : 'No reports yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showStarredOnly
                ? 'Star important reports to keep them close at hand.'
                : 'Generate your first report to create a downloadable PDF summary of recent symptoms.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFFC4CBD6),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF18242C),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFDBE3ED).withValues(alpha: 0.08)),
  );
}

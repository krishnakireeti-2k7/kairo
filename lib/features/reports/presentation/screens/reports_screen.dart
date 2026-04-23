import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _reportSubscription = ref.listenManual(reportProvider, (_, next) {
      if (next.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: const Color(0xFF7A2F36),
            ),
          );
        ref.read(reportProvider.notifier).clearError();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadReports();
    });
  }

  @override
  void dispose() {
    _reportSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09131A),
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF79D9E2),
          backgroundColor: const Color(0xFF162129),
          onRefresh: () => ref.read(reportProvider.notifier).loadReports(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF5F7FA),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Generate AI-assisted PDF reports from your recent symptom history.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Color(0xFFC4CBD6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: state.isGenerating
                                ? null
                                : () {
                                    ref.read(reportProvider.notifier).generateReport();
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2469AE),
                              foregroundColor: const Color(0xFFE8F2FF),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: state.isGenerating
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
                    ),
                    const SizedBox(height: 18),
                    if (state.isLoading)
                      const _LoadingCard()
                    else if (state.reports.isEmpty)
                      const _EmptyReportsCard()
                    else
                      ...state.reports.asMap().entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key == state.reports.length - 1 ? 0 : 14,
                          ),
                          child: ReportCard(
                            report: entry.value,
                            onOpen: () => _launch(entry.value.url),
                            onDownload: () => _launch(
                              entry.value.url,
                              external: true,
                            ),
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

  Future<void> _launch(String url, {bool external = false}) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open report.'),
            backgroundColor: Color(0xFF7A2F36),
          ),
        );
    }
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

class _EmptyReportsCard extends StatelessWidget {
  const _EmptyReportsCard();

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
            'No reports yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Generate your first report to create a downloadable PDF summary of recent symptoms.',
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

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF182129),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: const Color(0xFFDBE3ED).withValues(alpha: 0.05),
    ),
  );
}

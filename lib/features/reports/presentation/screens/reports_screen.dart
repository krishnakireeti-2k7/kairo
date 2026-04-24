import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kairo/features/reports/presentation/providers/report_provider.dart';
import 'package:kairo/features/reports/presentation/widgets/report_card.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final ProviderSubscription<ReportState> _reportSubscription;
  PdfControllerPinch? _pdfController;
  bool _showPdf = false;
  bool _pdfLoading = false;
  String? _pdfError;
  String? _openedUrl;

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
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _openPdf(String url) async {
    // Already showing this PDF — collapse it
    if (_showPdf && _openedUrl == url) {
      _pdfController?.dispose();
      setState(() {
        _showPdf = false;
        _pdfController = null;
        _openedUrl = null;
        _pdfError = null;
      });
      return;
    }

    // Dispose previous if switching reports
    _pdfController?.dispose();
    setState(() {
      _showPdf = true;
      _pdfLoading = true;
      _pdfError = null;
      _openedUrl = url;
      _pdfController = null;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      final controller = PdfControllerPinch(
        document: PdfDocument.openData(response.bodyBytes),
      );
      if (!mounted) return;
      setState(() {
        _pdfController = controller;
        _pdfLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pdfLoading = false;
        _pdfError = e.toString();
      });
    }
  }

  void _closePdf() {
    _pdfController?.dispose();
    setState(() {
      _showPdf = false;
      _pdfController = null;
      _openedUrl = null;
      _pdfError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    // Full-screen PDF view
    if (_showPdf) {
      return Scaffold(
        backgroundColor: const Color(0xFF09131A),
        appBar: AppBar(
          title: const Text('Report'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closePdf,
          ),
          actions: [
            if (_openedUrl != null)
              IconButton(
                onPressed: () => launchUrl(
                  Uri.parse(_openedUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.download_rounded),
              ),
          ],
        ),
        body: _buildPdfBody(),
      );
    }

    // Normal reports list
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
                                : () => ref
                                      .read(reportProvider.notifier)
                                      .generateReport(),
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
                            bottom: entry.key == state.reports.length - 1
                                ? 0
                                : 14,
                          ),
                          child: ReportCard(
                            report: entry.value,
                            onOpen: () => _openPdf(entry.value.url),
                            onDownload: () => launchUrl(
                              Uri.parse(entry.value.url),
                              mode: LaunchMode.externalApplication,
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

  Widget _buildPdfBody() {
    if (_pdfLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF79D9E2)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading report...',
              style: TextStyle(color: Color(0xFFC4CBD6), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_pdfError != null || _pdfController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 48,
                color: Color(0xFF79D9E2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load report',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF5F7FA),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _pdfError ?? 'Unknown error',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFFC4CBD6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(_openedUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open in Browser'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2469AE),
                  foregroundColor: const Color(0xFFE8F2FF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PdfViewPinch(
      controller: _pdfController!,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF79D9E2)),
          ),
        ),
        pageLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF79D9E2)),
          ),
        ),
        errorBuilder: (_, error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _pdfError = error.toString();
                _pdfController = null;
              });
            }
          });
          return const SizedBox.shrink();
        },
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
    border: Border.all(color: const Color(0xFFDBE3ED).withValues(alpha: 0.05)),
  );
}

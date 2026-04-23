import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/features/reports/data/services/report_service.dart';
import 'package:kairo/features/reports/domain/models/report_model.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});

final reportProvider = NotifierProvider<ReportNotifier, ReportState>(
  ReportNotifier.new,
);

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() {
    return const ReportState();
  }

  Future<void> loadReports() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final reports = await ref.read(reportServiceProvider).fetchReports();
      state = state.copyWith(
        reports: reports,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> generateReport() async {
    if (state.isGenerating) {
      return;
    }

    state = state.copyWith(
      isGenerating: true,
      errorMessage: null,
    );

    try {
      final report = await ref.read(reportServiceProvider).generateReport();
      state = state.copyWith(
        reports: [report, ...state.reports],
        isGenerating: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    state = state.copyWith(errorMessage: null);
  }
}

class ReportState {
  final List<ReportModel> reports;
  final bool isLoading;
  final bool isGenerating;
  final String? errorMessage;

  const ReportState({
    this.reports = const <ReportModel>[],
    this.isLoading = false,
    this.isGenerating = false,
    this.errorMessage,
  });

  ReportState copyWith({
    List<ReportModel>? reports,
    bool? isLoading,
    bool? isGenerating,
    Object? errorMessage = _sentinel,
  }) {
    return ReportState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

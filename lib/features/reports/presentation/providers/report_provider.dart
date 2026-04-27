import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/features/reports/data/report_repository.dart';
import 'package:kairo/features/reports/data/services/report_service.dart';
import 'package:kairo/features/reports/domain/models/report_model.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(reportServiceProvider));
});

final reportsProvider = NotifierProvider<ReportsNotifier, ReportsState>(
  ReportsNotifier.new,
);

final reportProvider = reportsProvider;

final starredReportsProvider = Provider<List<ReportModel>>((ref) {
  return ref
      .watch(reportsProvider)
      .reports
      .where((report) {
        return report.isStarred;
      })
      .toList(growable: false);
});

final reportActionsProvider = Provider<ReportsNotifier>((ref) {
  return ref.read(reportsProvider.notifier);
});

class ReportsNotifier extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    return const ReportsState();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final reports = await ref.read(reportRepositoryProvider).fetchReports();
      if (!ref.mounted) return;
      state = state.copyWith(
        reports: reports,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> generateReport() async {
    if (state.isGenerating) {
      return;
    }

    state = state.copyWith(isGenerating: true, errorMessage: null);

    try {
      final report = await ref.read(reportRepositoryProvider).generateReport();
      if (!ref.mounted) return;
      state = state.copyWith(
        reports: [report, ...state.reports],
        isGenerating: false,
        errorMessage: null,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isGenerating: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> renameReport({
    required String reportId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(errorMessage: 'Report name cannot be empty.');
      return;
    }

    final previousReports = state.reports;
    updateReportLocally(
      reportId,
      (report) => report.copyWith(name: trimmedName),
    );

    try {
      final updatedReport = await ref
          .read(reportRepositoryProvider)
          .renameReport(reportId: reportId, name: trimmedName);
      if (!ref.mounted) return;
      updateReportLocally(reportId, (_) => updatedReport);
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        reports: previousReports,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> toggleStar(ReportModel report) async {
    if (state.pendingStarIds.contains(report.id)) {
      return;
    }

    final previousReports = state.reports;
    final nextStarred = !report.isStarred;
    state = state.copyWith(
      reports: _replaceReport(
        report.id,
        (current) => current.copyWith(isStarred: nextStarred),
      ),
      pendingStarIds: {...state.pendingStarIds, report.id},
      errorMessage: null,
    );

    try {
      final updatedReport = await ref
          .read(reportRepositoryProvider)
          .setStarred(reportId: report.id, isStarred: nextStarred);
      if (!ref.mounted) return;
      final pending = {...state.pendingStarIds}..remove(report.id);
      state = state.copyWith(
        reports: _replaceReport(report.id, (_) => updatedReport),
        pendingStarIds: pending,
      );
    } catch (error) {
      if (!ref.mounted) return;
      final pending = {...state.pendingStarIds}..remove(report.id);
      state = state.copyWith(
        reports: previousReports,
        pendingStarIds: pending,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> deleteReport(String reportId) async {
    final previousReports = state.reports;
    state = state.copyWith(
      reports: state.reports.where((report) => report.id != reportId).toList(),
      deletingReportIds: {...state.deletingReportIds, reportId},
      errorMessage: null,
    );

    try {
      await ref.read(reportRepositoryProvider).deleteReport(reportId);
      if (!ref.mounted) return;
      final deleting = {...state.deletingReportIds}..remove(reportId);
      state = state.copyWith(deletingReportIds: deleting);
    } catch (error) {
      if (!ref.mounted) return;
      final deleting = {...state.deletingReportIds}..remove(reportId);
      state = state.copyWith(
        reports: previousReports,
        deletingReportIds: deleting,
        errorMessage: error.toString(),
      );
    }
  }

  void updateReportLocally(
    String reportId,
    ReportModel Function(ReportModel report) update,
  ) {
    state = state.copyWith(
      reports: _replaceReport(reportId, update),
      errorMessage: null,
    );
  }

  List<ReportModel> _replaceReport(
    String reportId,
    ReportModel Function(ReportModel report) update,
  ) {
    return state.reports
        .map((report) {
          if (report.id != reportId) {
            return report;
          }

          return update(report);
        })
        .toList(growable: false);
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    state = state.copyWith(errorMessage: null);
  }
}

typedef ReportNotifier = ReportsNotifier;
typedef ReportState = ReportsState;

class ReportsState {
  final List<ReportModel> reports;
  final bool isLoading;
  final bool isGenerating;
  final Set<String> pendingStarIds;
  final Set<String> deletingReportIds;
  final String? errorMessage;

  const ReportsState({
    this.reports = const <ReportModel>[],
    this.isLoading = false,
    this.isGenerating = false,
    this.pendingStarIds = const <String>{},
    this.deletingReportIds = const <String>{},
    this.errorMessage,
  });

  ReportsState copyWith({
    List<ReportModel>? reports,
    bool? isLoading,
    bool? isGenerating,
    Set<String>? pendingStarIds,
    Set<String>? deletingReportIds,
    Object? errorMessage = _sentinel,
  }) {
    return ReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      pendingStarIds: pendingStarIds ?? this.pendingStarIds,
      deletingReportIds: deletingReportIds ?? this.deletingReportIds,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

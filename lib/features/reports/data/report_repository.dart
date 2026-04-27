import 'package:kairo/features/reports/data/services/report_service.dart';
import 'package:kairo/features/reports/domain/models/report_model.dart';

class ReportRepository {
  ReportRepository(this._service);

  final ReportService _service;

  Future<List<ReportModel>> fetchReports() {
    return _service.fetchReports();
  }

  Future<ReportModel> generateReport() {
    return _service.generateReport();
  }

  Future<ReportModel> renameReport({
    required String reportId,
    required String name,
  }) {
    return _service.renameReport(reportId: reportId, name: name);
  }

  Future<ReportModel> setStarred({
    required String reportId,
    required bool isStarred,
  }) {
    return _service.setStarred(reportId: reportId, isStarred: isStarred);
  }

  Future<void> deleteReport(String reportId) {
    return _service.deleteReport(reportId);
  }
}

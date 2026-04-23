import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kairo/features/reports/domain/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  Future<List<ReportModel>> fetchReports() async {
    final accessToken = _accessToken;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/reports'),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(_formatError(decoded, 'Failed to fetch reports.'));
    }

    final reports = decoded['reports'] as List<dynamic>? ?? const [];
    return reports
        .map((item) => ReportModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<ReportModel> generateReport() async {
    final accessToken = _accessToken;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/generate-report'),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(_formatError(decoded, 'Failed to generate report.'));
    }

    return ReportModel.fromJson(decoded);
  }

  String get _accessToken {
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (session == null || accessToken == null || accessToken.isEmpty) {
      throw Exception('No active Supabase session found.');
    }

    return accessToken;
  }

  String _formatError(Map<String, dynamic> decoded, String fallback) {
    final error = decoded['error'] as String? ?? fallback;
    final details = decoded['details'] as String?;
    return details == null || details.isEmpty ? error : '$error: $details';
  }
}

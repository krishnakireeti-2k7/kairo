import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kairo/features/reports/domain/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  static const String _baseUrl = 'http://10.0.2.2:3000';

  Future<List<ReportModel>> fetchReports() async {
    final accessToken = _accessToken;

    final url = Uri.parse('$_baseUrl/reports');
    _logRequest(url);

    final response = await http.get(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    _logResponse(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch reports: ${response.body}');
    }

    final decoded = _decodeJsonObject(response.body);
    final reports = decoded['reports'] as List<dynamic>? ?? const [];
    return reports
        .map(
          (item) =>
              ReportModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ReportModel> generateReport() async {
    final accessToken = _accessToken;

    final url = Uri.parse('$_baseUrl/generate-report');
    _logRequest(url);

    final response = await http.post(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    _logResponse(response);

    if (response.statusCode != 201) {
      throw Exception('Failed to generate report: ${response.body}');
    }

    final decoded = _decodeJsonObject(response.body);
    return ReportModel.fromJson(decoded);
  }

  Future<ReportModel> renameReport({
    required String reportId,
    required String name,
  }) async {
    final accessToken = _accessToken;
    final url = Uri.parse('$_baseUrl/reports/$reportId');
    _logRequest(url);
    print('PATCH URL: $url');

    final response = await http.patch(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(<String, dynamic>{'name': name}),
    );
    _logResponse(response);
    print('Response: ${response.body}');

    if (response.statusCode != 200) {
      if (_isMissingPatchEndpoint(response)) {
        print('PATCH endpoint missing. Falling back to Supabase rename.');
        return _updateReportMetadata(reportId, <String, dynamic>{'name': name});
      }

      throw Exception('Failed to rename report: ${response.body}');
    }

    final data = _decodeJsonObject(response.body);
    return ReportModel.fromJson(data);
  }

  Future<ReportModel> setStarred({
    required String reportId,
    required bool isStarred,
  }) async {
    final accessToken = _accessToken;
    final url = Uri.parse('$_baseUrl/reports/$reportId');
    _logRequest(url);
    print('PATCH URL: $url');

    final response = await http.patch(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(<String, dynamic>{'is_starred': isStarred}),
    );
    _logResponse(response);
    print('Response: ${response.body}');

    if (response.statusCode != 200) {
      if (_isMissingPatchEndpoint(response)) {
        print('PATCH endpoint missing. Falling back to Supabase star update.');
        return _updateReportMetadata(reportId, <String, dynamic>{
          'is_starred': isStarred,
        });
      }

      throw Exception('Failed to update report: ${response.body}');
    }

    final data = _decodeJsonObject(response.body);
    return ReportModel.fromJson(data);
  }

  Future<void> deleteReport(String reportId) async {
    final accessToken = _accessToken;
    final url = Uri.parse('$_baseUrl/reports/$reportId');
    _logRequest(url);

    final response = await http.delete(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    _logResponse(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete report: ${response.body}');
    }
  }

  String get _accessToken {
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (session == null || accessToken == null || accessToken.isEmpty) {
      throw Exception('No active Supabase session found.');
    }

    return accessToken;
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<ReportModel> _updateReportMetadata(
    String reportId,
    Map<String, dynamic> values,
  ) async {
    final data = await _client
        .from('reports')
        .update(values)
        .eq('id', reportId)
        .select('id, name, file_url, created_at, is_starred')
        .single();

    return ReportModel.fromJson(Map<String, dynamic>.from(data));
  }

  bool _isMissingPatchEndpoint(http.Response response) {
    return response.statusCode == 404 &&
        response.body.contains('Cannot PATCH /reports/');
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on FormatException catch (error) {
      throw FormatException(
        'Expected JSON from reports API but received: $body',
        error.source,
        error.offset,
      );
    }
  }

  void _logRequest(Uri url) {
    print('Request URL: $url');
  }

  void _logResponse(http.Response response) {
    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  }
}

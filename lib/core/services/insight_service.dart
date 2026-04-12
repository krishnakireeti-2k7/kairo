import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kairo/core/services/supabase_service.dart';

class InsightService {
  Future<String> fetchInsight() async {
    final session = SupabaseService.client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No active Supabase session found.');
    }

    final uri = Uri.parse(_baseUrl).replace(path: '/analyze');
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(const <String, dynamic>{})));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to fetch insight: ${response.statusCode} $body',
        );
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final insight = decoded['insight'] as String?;

      if (insight == null || insight.trim().isEmpty) {
        throw Exception('Backend returned an empty insight.');
      }

      return insight;
    } finally {
      client.close(force: true);
    }
  }

  String get _baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class InsightService {
  Future<String> fetchInsights() async {
    final supabase = Supabase.instance.client;

    // ✅ Force refresh
    await supabase.auth.refreshSession();

    final session = supabase.auth.currentSession;
    final accessToken = session?.accessToken;

    if (session == null || accessToken == null || accessToken.isEmpty) {
      throw Exception('No valid Supabase session found.');
    }

    // 🔍 Debug
    print("FRESH TOKEN: $accessToken");

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/analyze'),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(const <String, dynamic>{}),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final insight = decoded['insight'] as String?;

    if (insight == null || insight.trim().isEmpty) {
      throw Exception('Insight not found in response.');
    }

    return insight;
  }

  Future<String> fetchInsight() {
    return fetchInsights();
  }
}

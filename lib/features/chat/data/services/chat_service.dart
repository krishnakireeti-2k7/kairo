import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kairo/features/chat/domain/models/chat_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  Future<String> sendMessage({
    required String message,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (session == null || accessToken == null || accessToken.isEmpty) {
      throw Exception('No active Supabase session found.');
    }

    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/chat'),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': trimmedMessage,
      }),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final error = decoded['error'] as String? ?? 'Chat request failed.';
      final details = decoded['details'] as String?;
      throw Exception(
        details == null || details.isEmpty ? error : '$error: $details',
      );
    }

    final reply = decoded['reply'] as String?;
    if (reply == null || reply.trim().isEmpty) {
      throw Exception('Reply not found in response.');
    }

    return reply;
  }

  Future<List<ChatMessage>> fetchMessages() async {
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (session == null || accessToken == null || accessToken.isEmpty) {
      throw Exception('No active Supabase session found.');
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/messages'),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final error = decoded['error'] as String? ?? 'Failed to fetch messages.';
      final details = decoded['details'] as String?;
      throw Exception(
        details == null || details.isEmpty ? error : '$error: $details',
      );
    }

    final messages = decoded['messages'] as List<dynamic>? ?? const [];
    return messages.map((message) {
      final json = Map<String, dynamic>.from(message as Map);
      return ChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['created_at'] as String).toLocal(),
      );
    }).toList();
  }
}

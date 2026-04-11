import 'package:kairo/core/services/supabase_service.dart';
import 'package:kairo/features/logs/domain/models/log_model.dart';

class LogRepository {
  Future<void> createLog({
    required int severity,
    required int duration,
    required String notes,
    required DateTime timestamp,
    List<String> symptomIds = const [],
    List<String> contextIds = const [],
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final insertedLog = await SupabaseService.client
        .from('logs')
        .insert({
          'user_id': user.id,
          'timestamp': timestamp.toUtc().toIso8601String(),
          'severity': severity,
          'duration': duration,
          'notes': notes.trim(),
        })
        .select('id')
        .single();

    final logId = insertedLog['id'] as String;

    if (symptomIds.isNotEmpty) {
      final symptomRows = symptomIds
          .map((symptomId) => {'log_id': logId, 'symptom_id': symptomId})
          .toList();
      await SupabaseService.client.from('log_symptoms').insert(symptomRows);
    }

    if (contextIds.isNotEmpty) {
      final contextRows = contextIds
          .map((contextId) => {'log_id': logId, 'context_id': contextId})
          .toList();
      await SupabaseService.client.from('log_context').insert(contextRows);
    }
  }

  Future<List<LogModel>> fetchLogs() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await SupabaseService.client
        .from('logs')
        .select('''
          id,
          user_id,
          timestamp,
          severity,
          duration,
          notes,
          log_symptoms(
            symptoms(
              name
            )
          )
        ''')
        .eq('user_id', user.id)
        .order('timestamp', ascending: false);

    return (response as List<dynamic>)
        .map((json) => LogModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

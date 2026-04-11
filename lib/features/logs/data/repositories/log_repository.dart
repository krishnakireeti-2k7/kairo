import 'package:kairo/core/services/supabase_service.dart';
import 'package:kairo/features/logs/domain/models/log_model.dart';

class LogRepository {
  Future<void> createLog({
    required int severity,
    required int duration,
    required String notes,
    required DateTime timestamp,
    List<String> symptoms = const [],
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await SupabaseService.client.from('logs').insert({
      'user_id': user.id,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'severity': severity,
      'duration': duration,
      'notes': notes.trim(),
      'symptoms': symptoms,
    });
  }

  Future<List<LogModel>> fetchLogs() async {
    print('Fetching logs...');
    final user = SupabaseService.currentUser;
    print('User: ${user?.id}');

    if (user == null) {
      throw Exception(
        'Cannot fetch logs because no authenticated user was found.',
      );
    }

    final response = await SupabaseService.client
        .from('logs')
        .select('*')
        .eq('user_id', user.id)
        .order('timestamp', ascending: false);

    print('Response: $response');

    return (response as List<dynamic>)
        .map((json) => LogModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

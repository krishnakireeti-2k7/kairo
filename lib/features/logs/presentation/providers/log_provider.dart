import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/services/insight_service.dart';
import 'package:kairo/features/logs/domain/models/log_model.dart';
import 'package:kairo/features/logs/data/repositories/log_repository.dart';

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository();
});

final logsProvider = FutureProvider<List<LogModel>>((ref) async {
  final repo = ref.read(logRepositoryProvider);
  return await repo.fetchLogs().timeout(const Duration(seconds: 10));
});

final insightProvider = FutureProvider<String>((ref) async {
  final service = InsightService();
  return service.fetchInsight();
});

final logSubmissionProvider = NotifierProvider<LogSubmissionNotifier, bool>(
  LogSubmissionNotifier.new,
);

final logFormProvider = NotifierProvider<LogFormNotifier, LogFormState>(
  LogFormNotifier.new,
);

class LogSubmissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setSubmitting(bool value) {
    state = value;
  }
}

class LogFormNotifier extends Notifier<LogFormState> {
  @override
  LogFormState build() {
    return LogFormState.initial();
  }

  void setSeverity(int value) {
    state = state.copyWith(severity: value);
  }

  void setDuration(int value) {
    state = state.copyWith(duration: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void setTimestamp(DateTime value) {
    state = state.copyWith(timestamp: value);
  }

  void setSymptomSearch(String value) {
    state = state.copyWith(symptomSearch: value);
  }

  void addSymptom(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }

    final exists = state.symptoms.any(
      (symptom) => symptom.toLowerCase() == normalized.toLowerCase(),
    );
    if (exists) {
      state = state.copyWith(symptomSearch: '');
      return;
    }

    state = state.copyWith(
      symptoms: [...state.symptoms, normalized],
      symptomSearch: '',
    );
  }

  void removeSymptom(String value) {
    state = state.copyWith(
      symptoms: state.symptoms.where((symptom) => symptom != value).toList(),
    );
  }

  void reset() {
    state = LogFormState.initial();
  }
}

class LogFormState {
  final int severity;
  final int duration;
  final String notes;
  final DateTime timestamp;
  final String symptomSearch;
  final List<String> symptoms;

  const LogFormState({
    required this.severity,
    required this.duration,
    required this.notes,
    required this.timestamp,
    required this.symptomSearch,
    required this.symptoms,
  });

  factory LogFormState.initial() {
    return LogFormState(
      severity: 7,
      duration: 240,
      notes: '',
      timestamp: DateTime.now(),
      symptomSearch: '',
      symptoms: const <String>[],
    );
  }

  LogFormState copyWith({
    int? severity,
    int? duration,
    String? notes,
    DateTime? timestamp,
    String? symptomSearch,
    List<String>? symptoms,
  }) {
    return LogFormState(
      severity: severity ?? this.severity,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      symptomSearch: symptomSearch ?? this.symptomSearch,
      symptoms: symptoms ?? this.symptoms,
    );
  }
}

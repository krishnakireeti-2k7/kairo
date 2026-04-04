import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/features/logs/data/repositories/log_repository.dart';
import 'package:kairo/features/logs/domain/models/log_model.dart';

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository();
});

final logProvider = AsyncNotifierProvider<LogNotifier, List<LogModel>>(
  LogNotifier.new,
);

class LogNotifier extends AsyncNotifier<List<LogModel>> {
  @override
  FutureOr<List<LogModel>> build() async {
    return ref.read(logRepositoryProvider).fetchLogs();
  }

  Future<void> loadLogs() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(logRepositoryProvider).fetchLogs(),
    );
  }

  Future<void> createLog({
    required int severity,
    required int duration,
    required String notes,
    required DateTime timestamp,
    List<String> symptomIds = const [],
    List<String> contextIds = const [],
  }) async {
    final repository = ref.read(logRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.createLog(
        severity: severity,
        duration: duration,
        notes: notes,
        timestamp: timestamp,
        symptomIds: symptomIds,
        contextIds: contextIds,
      );
      return repository.fetchLogs();
    });
  }
}

final logFormProvider = NotifierProvider<LogFormNotifier, LogFormState>(
  LogFormNotifier.new,
);

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

  void toggleSymptom(String value) {
    final updated = <String>{...state.selectedSymptoms};
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    state = state.copyWith(selectedSymptoms: updated);
  }

  void toggleContext(String value) {
    final updated = <String>{...state.selectedContexts};
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    state = state.copyWith(selectedContexts: updated);
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
  final Set<String> selectedSymptoms;
  final Set<String> selectedContexts;

  const LogFormState({
    required this.severity,
    required this.duration,
    required this.notes,
    required this.timestamp,
    required this.symptomSearch,
    required this.selectedSymptoms,
    required this.selectedContexts,
  });

  factory LogFormState.initial() {
    return LogFormState(
      severity: 7,
      duration: 240,
      notes: '',
      timestamp: DateTime.now(),
      symptomSearch: '',
      selectedSymptoms: const <String>{},
      selectedContexts: const <String>{},
    );
  }

  LogFormState copyWith({
    int? severity,
    int? duration,
    String? notes,
    DateTime? timestamp,
    String? symptomSearch,
    Set<String>? selectedSymptoms,
    Set<String>? selectedContexts,
  }) {
    return LogFormState(
      severity: severity ?? this.severity,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      symptomSearch: symptomSearch ?? this.symptomSearch,
      selectedSymptoms: selectedSymptoms ?? this.selectedSymptoms,
      selectedContexts: selectedContexts ?? this.selectedContexts,
    );
  }
}

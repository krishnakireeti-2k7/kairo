import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/features/logs/domain/models/log_model.dart';
import 'package:kairo/features/logs/presentation/providers/log_provider.dart';

final timelineProvider = NotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);

class TimelineNotifier extends Notifier<TimelineState> {
  @override
  TimelineState build() {
    return const TimelineState();
  }

  Future<void> loadLogs() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final logs = await ref.read(logRepositoryProvider).fetchLogs();
      state = state.copyWith(
        logs: logs,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void setTimeFilter(TimelineTimeFilter filter) {
    if (state.timeFilter == filter) {
      return;
    }

    state = state.copyWith(timeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

enum TimelineTimeFilter {
  last7Days('Last 7 days'),
  lastMonth('1 month'),
  last3Months('3 months'),
  allTime('All time');

  final String label;

  const TimelineTimeFilter(this.label);
}

class TimelineState {
  final List<LogModel> logs;
  final TimelineTimeFilter timeFilter;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const TimelineState({
    this.logs = const <LogModel>[],
    this.timeFilter = TimelineTimeFilter.last7Days,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  List<LogModel> get filteredLogs {
    final cutoff = _cutoffFor(timeFilter);
    final normalizedQuery = searchQuery.trim().toLowerCase();

    return logs.where((log) {
      final matchesTime = cutoff == null || !log.timestamp.isBefore(cutoff);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          log.symptoms.any(
            (symptom) => symptom.toLowerCase().contains(normalizedQuery),
          );

      return matchesTime && matchesSearch;
    }).toList();
  }

  TimelineState copyWith({
    List<LogModel>? logs,
    TimelineTimeFilter? timeFilter,
    String? searchQuery,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return TimelineState(
      logs: logs ?? this.logs,
      timeFilter: timeFilter ?? this.timeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  DateTime? _cutoffFor(TimelineTimeFilter filter) {
    final now = DateTime.now();

    switch (filter) {
      case TimelineTimeFilter.last7Days:
        return now.subtract(const Duration(days: 7));
      case TimelineTimeFilter.lastMonth:
        return DateTime(now.year, now.month - 1, now.day);
      case TimelineTimeFilter.last3Months:
        return DateTime(now.year, now.month - 3, now.day);
      case TimelineTimeFilter.allTime:
        return null;
    }
  }
}

const Object _sentinel = Object();

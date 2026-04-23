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
        allLogs: logs,
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

  void setFilter(TimelineTimeFilter filter) {
    if (state.timeFilter == filter) {
      return;
    }

    state = state.copyWith(timeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setViewMode(TimelineViewMode mode) {
    if (state.viewMode == mode) {
      return;
    }

    state = state.copyWith(viewMode: mode);
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

enum TimelineViewMode {
  timeline('Timeline'),
  bySymptom('By Symptom');

  final String label;

  const TimelineViewMode(this.label);
}

class TimelineSummary {
  final String dateRangeLabel;
  final String mostFrequentLabel;
  final String averageSeverityLabel;
  final String trendLabel;

  const TimelineSummary({
    required this.dateRangeLabel,
    required this.mostFrequentLabel,
    required this.averageSeverityLabel,
    required this.trendLabel,
  });
}

class SymptomGroup {
  final String symptom;
  final List<LogModel> logs;

  const SymptomGroup({
    required this.symptom,
    required this.logs,
  });
}

class TimelineState {
  final List<LogModel> allLogs;
  final TimelineTimeFilter timeFilter;
  final TimelineViewMode viewMode;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const TimelineState({
    this.allLogs = const <LogModel>[],
    this.timeFilter = TimelineTimeFilter.allTime,
    this.viewMode = TimelineViewMode.timeline,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  List<LogModel> get filteredLogs {
    final cutoff = _cutoffFor(timeFilter);
    final normalizedQuery = searchQuery.trim().toLowerCase();

    return allLogs.where((log) {
      final matchesTime = cutoff == null || !log.timestamp.isBefore(cutoff);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          log.symptoms.any(
            (symptom) => symptom.toLowerCase().contains(normalizedQuery),
          );

      return matchesTime && matchesSearch;
    }).toList();
  }

  Map<String, List<LogModel>> get groupedTimelineLogs {
    final grouped = <String, List<LogModel>>{
      'Today': <LogModel>[],
      'Yesterday': <LogModel>[],
      'Older': <LogModel>[],
    };

    for (final log in filteredLogs) {
      grouped[_dayLabel(log.timestamp)]!.add(log);
    }

    grouped.removeWhere((_, value) => value.isEmpty);
    return grouped;
  }

  List<SymptomGroup> get groupedBySymptom {
    final grouped = <String, List<LogModel>>{};

    for (final log in filteredLogs) {
      final symptoms = log.symptoms.isEmpty ? const ['No symptoms'] : log.symptoms;
      for (final symptom in symptoms) {
        grouped.putIfAbsent(symptom, () => <LogModel>[]).add(log);
      }
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.length.compareTo(a.value.length);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return entries
        .map(
          (entry) => SymptomGroup(
            symptom: entry.key,
            logs: entry.value,
          ),
        )
        .toList();
  }

  TimelineSummary get summary {
    final logs = filteredLogs;
    if (logs.isEmpty) {
      return TimelineSummary(
        dateRangeLabel: _rangeLabel,
        mostFrequentLabel: 'No symptoms yet',
        averageSeverityLabel: 'No data',
        trendLabel: 'Stable',
      );
    }

    final counts = <String, int>{};
    for (final log in logs) {
      final symptoms = log.symptoms.isEmpty ? const ['No symptoms'] : log.symptoms;
      for (final symptom in symptoms) {
        counts.update(symptom, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final topSymptom = counts.entries.reduce((a, b) {
      if (a.value != b.value) {
        return a.value >= b.value ? a : b;
      }
      return a.key.toLowerCase().compareTo(b.key.toLowerCase()) <= 0 ? a : b;
    });

    final averageSeverity =
        logs.fold<int>(0, (total, log) => total + log.severity) / logs.length;

    return TimelineSummary(
      dateRangeLabel: _rangeLabel,
      mostFrequentLabel:
          '${_titleCase(topSymptom.key)} (${topSymptom.value} ${topSymptom.value == 1 ? 'time' : 'times'})',
      averageSeverityLabel: _averageSeverityLabel(averageSeverity),
      trendLabel: _trendLabel(logs),
    );
  }

  TimelineState copyWith({
    List<LogModel>? allLogs,
    TimelineTimeFilter? timeFilter,
    TimelineViewMode? viewMode,
    String? searchQuery,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return TimelineState(
      allLogs: allLogs ?? this.allLogs,
      timeFilter: timeFilter ?? this.timeFilter,
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  String get _rangeLabel {
    switch (timeFilter) {
      case TimelineTimeFilter.last7Days:
        return 'Last 7 days';
      case TimelineTimeFilter.lastMonth:
        return 'Last month';
      case TimelineTimeFilter.last3Months:
        return 'Last 3 months';
      case TimelineTimeFilter.allTime:
        return 'All time';
    }
  }
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

String _dayLabel(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final difference = today.difference(date).inDays;

  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  return 'Older';
}

String _averageSeverityLabel(double value) {
  if (value <= 2) {
    return 'Mild';
  }
  if (value < 4) {
    return 'Moderate';
  }
  return 'High';
}

String _trendLabel(List<LogModel> logs) {
  if (logs.length < 2) {
    return 'Stable';
  }

  final midpoint = logs.length ~/ 2;
  final recent = logs.take(midpoint == 0 ? 1 : midpoint).toList();
  final past = logs.skip(midpoint == 0 ? 1 : midpoint).toList();
  if (past.isEmpty) {
    return 'Stable';
  }

  final recentAverage =
      recent.fold<int>(0, (total, log) => total + log.severity) / recent.length;
  final pastAverage =
      past.fold<int>(0, (total, log) => total + log.severity) / past.length;
  final difference = recentAverage - pastAverage;

  if (difference >= 0.5) {
    return 'Increasing';
  }
  if (difference <= -0.5) {
    return 'Decreasing';
  }
  return 'Stable';
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1);
}

const Object _sentinel = Object();

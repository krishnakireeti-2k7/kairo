import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/services/insight_service.dart';

final insightProvider = FutureProvider<String>((ref) async {
  return InsightService().fetchInsights();
});

class LogModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final int severity;
  final int duration;
  final String notes;
  final List<String> symptoms;

  const LogModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.severity,
    required this.duration,
    required this.notes,
    required this.symptoms,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      severity: (json['severity'] as num).toInt(),
      duration: (json['duration'] as num).toInt(),
      notes: (json['notes'] as String?) ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? const <String>[]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'severity': severity,
      'duration': duration,
      'notes': notes,
      'symptoms': symptoms,
    };
  }
}

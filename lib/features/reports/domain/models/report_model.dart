class ReportModel {
  final String id;
  final String name;
  final String url;
  final DateTime createdAt;
  final bool isStarred;

  const ReportModel({
    required this.id,
    required this.name,
    required this.url,
    required this.createdAt,
    required this.isStarred,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Health Report',
      url: json['file_url'] as String? ?? json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      isStarred: json['is_starred'] as bool? ?? false,
    );
  }

  ReportModel copyWith({
    String? id,
    String? name,
    String? url,
    DateTime? createdAt,
    bool? isStarred,
  }) {
    return ReportModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}

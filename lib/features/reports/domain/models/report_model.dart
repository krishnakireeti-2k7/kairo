class ReportModel {
  final String id;
  final String url;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.url,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      url: json['file_url'] as String? ?? json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

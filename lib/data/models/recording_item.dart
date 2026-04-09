class RecordingItem {
  const RecordingItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    required this.durationSeconds,
    required this.status,
    this.summary,
  });

  final String id;
  final String title;
  final String filePath;
  final DateTime createdAt;
  final int durationSeconds;
  final String status;
  final String? summary;

  RecordingItem copyWith({
    String? id,
    String? title,
    String? filePath,
    DateTime? createdAt,
    int? durationSeconds,
    String? status,
    String? summary,
  }) {
    return RecordingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'status': status,
      'summary': summary,
    };
  }

  factory RecordingItem.fromJson(Map<String, dynamic> json) {
    return RecordingItem(
      id: json['id'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'saved',
      summary: json['summary'] as String?,
    );
  }
}

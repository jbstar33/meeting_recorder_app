class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.speaker,
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
  });

  final String id;
  final String speaker;
  final int startSeconds;
  final int endSeconds;
  final String text;

  TranscriptSegment copyWith({
    String? id,
    String? speaker,
    int? startSeconds,
    int? endSeconds,
    String? text,
  }) {
    return TranscriptSegment(
      id: id ?? this.id,
      speaker: speaker ?? this.speaker,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'speaker': speaker,
      'startSeconds': startSeconds,
      'endSeconds': endSeconds,
      'text': text,
    };
  }

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      id: json['id'] as String,
      speaker: json['speaker'] as String,
      startSeconds: (json['startSeconds'] as num?)?.toInt() ?? 0,
      endSeconds: (json['endSeconds'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
    );
  }
}

class TranscriptItem {
  const TranscriptItem({
    required this.id,
    required this.recordingId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.language,
    required this.segments,
    this.summary,
  });

  final String id;
  final String recordingId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String language;
  final List<TranscriptSegment> segments;
  final String? summary;

  String get fullText => segments.map((TranscriptSegment segment) => segment.text).join(' ');

  TranscriptItem copyWith({
    String? id,
    String? recordingId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? language,
    List<TranscriptSegment>? segments,
    String? summary,
  }) {
    return TranscriptItem(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      language: language ?? this.language,
      segments: segments ?? this.segments,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'recordingId': recordingId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'language': language,
      'segments': segments.map((TranscriptSegment s) => s.toJson()).toList(),
      'summary': summary,
    };
  }

  factory TranscriptItem.fromJson(Map<String, dynamic> json) {
    return TranscriptItem(
      id: json['id'] as String,
      recordingId: json['recordingId'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      language: json['language'] as String? ?? 'ko',
      segments: ((json['segments'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic item) => TranscriptSegment.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String?,
    );
  }
}

class LocalSttSegment {
  const LocalSttSegment({
    required this.speaker,
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
  });

  final String speaker;
  final int startSeconds;
  final int endSeconds;
  final String text;
}

class LocalSttResult {
  const LocalSttResult({
    required this.text,
    required this.language,
    required this.segments,
  });

  final String text;
  final String language;
  final List<LocalSttSegment> segments;
}

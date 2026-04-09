class RecordingPreview {
  const RecordingPreview({
    required this.title,
    required this.dateLabel,
    required this.durationLabel,
    required this.status,
    required this.preview,
    required this.speakers,
  });

  final String title;
  final String dateLabel;
  final String durationLabel;
  final String status;
  final String preview;
  final int speakers;
}

class TranscriptSegmentPreview {
  const TranscriptSegmentPreview({
    required this.speaker,
    required this.timeLabel,
    required this.text,
  });

  final String speaker;
  final String timeLabel;
  final String text;
}

const List<RecordingPreview> mockRecordings = <RecordingPreview>[
  RecordingPreview(
    title: 'Weekly Product Strategy',
    dateLabel: '2026.04.09 14:30',
    durationLabel: '42 min',
    status: 'Analyzed',
    preview: 'Launch timing, offline AI processing, and the Android MVP scope were discussed.',
    speakers: 4,
  ),
  RecordingPreview(
    title: 'Design Review',
    dateLabel: '2026.04.08 10:00',
    durationLabel: '18 min',
    status: 'Transcribed',
    preview: 'The home structure, recording interactions, and rounded card UI were aligned.',
    speakers: 3,
  ),
  RecordingPreview(
    title: 'Customer Interview Notes',
    dateLabel: '2026.04.07 16:40',
    durationLabel: '27 min',
    status: 'Pending',
    preview: 'Security, PIN lock, and no-cloud expectations were strongly validated.',
    speakers: 2,
  ),
];

const List<TranscriptSegmentPreview> mockSegments = <TranscriptSegmentPreview>[
  TranscriptSegmentPreview(
    speaker: 'SPEAKER_00',
    timeLabel: '00:00 - 00:32',
    text: 'Today we will lock the MVP scope for the offline-first meeting recorder and confirm the Android-first launch plan.',
  ),
  TranscriptSegmentPreview(
    speaker: 'SPEAKER_01',
    timeLabel: '00:33 - 01:08',
    text: 'The key point is that recording must start quickly, and while transcription can come later, the UI quality should feel polished from day one.',
  ),
  TranscriptSegmentPreview(
    speaker: 'SPEAKER_02',
    timeLabel: '01:09 - 01:41',
    text: 'First verify that the home, recording, transcript, analysis, and settings screens connect naturally.',
  ),
];

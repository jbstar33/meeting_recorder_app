import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/recording_item.dart';
import '../../data/models/transcript_item.dart';

class TranscriptExportService {
  Future<String?> exportMarkdown(
    TranscriptItem transcript, {
    RecordingItem? recording,
  }) async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final Directory exportsDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}exports',
    );
    await exportsDirectory.create(recursive: true);

    final String fileName = _buildFileName(transcript);
    final File file = File('${exportsDirectory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(_buildMarkdown(transcript, recording: recording));
    return file.path;
  }

  String _buildMarkdown(
    TranscriptItem transcript, {
    RecordingItem? recording,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('# ${transcript.title}')
      ..writeln()
      ..writeln('- Created: ${formatDateTime(transcript.createdAt)}')
      ..writeln('- Updated: ${formatDateTime(transcript.updatedAt)}')
      ..writeln('- Language: ${transcript.language.toUpperCase()}')
      ..writeln('- Segments: ${transcript.segments.length}');

    if (recording != null) {
      buffer
        ..writeln('- Recording file: ${recording.filePath}')
        ..writeln('- Recording duration: ${formatDuration(recording.durationSeconds)}');
    }

    if ((transcript.summary ?? '').trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Summary')
        ..writeln(transcript.summary!.trim());
    }

    buffer
      ..writeln()
      ..writeln('## Transcript');

    for (final TranscriptSegment segment in transcript.segments) {
      buffer
        ..writeln()
        ..writeln('### ${segment.speaker} - ${formatRange(segment.startSeconds, segment.endSeconds)}')
        ..writeln(segment.text.trim());
    }

    return buffer.toString();
  }

  String _buildFileName(TranscriptItem transcript) {
    final String safeTitle = transcript.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final String timestamp = transcript.createdAt.toIso8601String().replaceAll(':', '-');
    return '${safeTitle.isEmpty ? 'transcript' : safeTitle}_$timestamp.md';
  }
}

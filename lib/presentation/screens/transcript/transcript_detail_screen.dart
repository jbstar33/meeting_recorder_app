import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/recording_item.dart';
import '../../../data/models/transcript_item.dart';
import '../../widgets/audio_player_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/speaker_chip.dart';

class TranscriptDetailScreen extends StatelessWidget {
  const TranscriptDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final TranscriptItem? item = controller.selectedTranscript;
    final RecordingItem? recording =
        item == null ? controller.selectedRecording : controller.recordingForTranscript(item.id);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('\uB179\uC74C \uC0C1\uC138'),
      ),
      body: item == null
          ? const Center(
              child: Text('\uBA3C\uC800 \uB179\uC74C\uC744 \uC120\uD0DD\uD558\uC138\uC694.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item.title, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${formatDateTime(item.createdAt)} - ${item.language.toUpperCase()}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          SpeakerChip(label: '${item.segments.length} segments', index: 0),
                          const SpeakerChip(label: 'Editable', index: 1),
                          const SpeakerChip(label: 'Searchable', index: 2),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () async {
                              final String? updated = await _openEditDialog(
                                context,
                                title: '\uB179\uC74C \uC81C\uBAA9 \uC218\uC815',
                                label: '\uB179\uC74C \uC81C\uBAA9',
                                initialText: item.title,
                                maxLines: 2,
                              );
                              if (updated != null && updated.trim().isNotEmpty) {
                                await controller.updateTranscriptMetadata(
                                  transcriptId: item.id,
                                  title: updated.trim(),
                                );
                              }
                            },
                            icon: const Icon(Icons.title),
                            label: const Text('\uC81C\uBAA9 \uC218\uC815'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final String? updated = await _openEditDialog(
                                context,
                                title: '\uC694\uC57D \uC218\uC815',
                                label: '\uC694\uC57D',
                                initialText: item.summary ?? '',
                                maxLines: 5,
                              );
                              if (updated != null) {
                                await controller.updateTranscriptMetadata(
                                  transcriptId: item.id,
                                  summary: updated.trim().isEmpty ? null : updated.trim(),
                                );
                              }
                            },
                            icon: const Icon(Icons.notes_outlined),
                            label: const Text('\uC694\uC57D \uC218\uC815'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final bool confirmed = await _confirmDelete(context);
                              if (confirmed) {
                                await controller.deleteTranscript(item.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('\uC0AD\uC81C'),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: _buildMarkdownPreview(item, recording)));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('\uB179\uC74C Markdown\uC774 \uBCF5\uC0AC\uB428.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Markdown \uBCF5\uC0AC'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final String? path = await controller.exportTranscript(item.id);
                              if (context.mounted && path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('\uB0B4\uBCF4\uB0B4\uAE30 \uC644\uB8CC: $path')),
                                );
                              }
                            },
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Markdown \uB0B4\uBCF4\uB0B4\uAE30'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              '\uB179\uC74C \uC694\uC57D',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.summary ??
                                  '\uC774 \uB179\uC74C\uC740 STT \uC5D4\uC9C4\uC774 \uC5F0\uACB0\uB418\uAE30 \uC804\uC5D0 \uB9CC\uB4E4\uC5B4\uC9C4 \uCD08\uC548\uC785\uB2C8\uB2E4.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...item.segments.map((TranscriptSegment segment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SegmentCard(
                      segment: segment,
                      onEdit: () async {
                        final String? updated = await _openEditDialog(
                          context,
                          title: '\uAD6C\uAC04 \uC218\uC815',
                          label: '\uAD6C\uAC04 \uB0B4\uC6A9',
                          initialText: segment.text,
                          maxLines: 6,
                        );
                        if (updated != null && updated.trim().isNotEmpty) {
                          await controller.updateTranscriptSegment(
                            transcriptId: item.id,
                            segmentId: segment.id,
                            newText: updated.trim(),
                          );
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _InfoCard(
                  title: '\uC800\uC7A5\uB41C \uD30C\uC77C',
                  body: recording?.filePath ?? '\uB85C\uCEEC \uB179\uC74C \uD30C\uC77C\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.',
                  tone: AppColors.primary,
                ),
                const SizedBox(height: 12),
                AudioPlayerCard(filePath: recording?.filePath),
              ],
            ),
    );
  }

  Future<String?> _openEditDialog(
    BuildContext context, {
    required String title,
    required String label,
    required String initialText,
    int maxLines = 6,
  }) {
    final TextEditingController controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              alignLabelWithHint: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('\uC800\uC7A5'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('\uB179\uC74C \uC0AD\uC81C'),
          content: const Text('\uC774 \uB179\uC74C\uC740 \uAE30\uAE30\uC5D0\uC11C \uC0AD\uC81C\uB429\uB2C8\uB2E4.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('\uC0AD\uC81C'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String _buildMarkdownPreview(TranscriptItem transcript, RecordingItem? recording) {
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
        ..writeln('## \uC694\uC57D')
        ..writeln(transcript.summary!.trim());
    }

    buffer.writeln();
    buffer.writeln('## \uB179\uC74C \uB0B4\uC6A9');
    for (final TranscriptSegment segment in transcript.segments) {
      buffer
        ..writeln()
        ..writeln('### ${segment.speaker} · ${formatRange(segment.startSeconds, segment.endSeconds)}')
        ..writeln(segment.text.trim());
    }
    return buffer.toString();
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.segment,
    required this.onEdit,
  });

  final TranscriptSegment segment;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SpeakerChip(label: segment.speaker, index: 0),
              const SizedBox(width: 10),
              Text(formatRange(segment.startSeconds, segment.endSeconds)),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('\uC218\uC815'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(segment.text),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    required this.tone,
  });

  final String title;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tone.withValues(alpha: 0.18),
            tone.withValues(alpha: 0.07),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, color: tone),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tone,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

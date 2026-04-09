import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/recording_item.dart';
import '../../../data/models/transcript_item.dart';
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
        title: const Text('Transcript detail'),
      ),
      body: item == null
          ? const Center(
              child: Text('Choose or create a recording first.'),
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
                                title: 'Edit transcript title',
                                label: 'Transcript title',
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
                            label: const Text('Edit title'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final String? updated = await _openEditDialog(
                                context,
                                title: 'Edit summary',
                                label: 'Transcript summary',
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
                            label: const Text('Edit summary'),
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
                            label: const Text('Delete'),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: _buildMarkdownPreview(item, recording)));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transcript markdown copied to clipboard.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Markdown'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final String? path = await controller.exportTranscript(item.id);
                              if (context.mounted && path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Exported to $path')),
                                );
                              }
                            },
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Export Markdown'),
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
                              'Transcript summary',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.summary ??
                                  'This transcript is a draft created from the recording until the STT engine is connected.',
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
                          title: 'Edit segment',
                          label: 'Segment text',
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
                  title: 'Stored file',
                  body: recording?.filePath ?? 'No local recording file found.',
                  tone: AppColors.primary,
                ),
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
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
          title: const Text('Delete transcript'),
          content: const Text('This transcript will be removed from the local device.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
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
        ..writeln('## Summary')
        ..writeln(transcript.summary!.trim());
    }

    buffer.writeln();
    buffer.writeln('## Transcript');
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
                label: const Text('Edit'),
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

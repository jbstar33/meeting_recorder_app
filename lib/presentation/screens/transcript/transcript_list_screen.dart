import 'package:flutter/material.dart';

import '../../../app_state/app_scope.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transcript_item.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/speaker_chip.dart';
import 'transcript_detail_screen.dart';

class TranscriptListScreen extends StatelessWidget {
  const TranscriptListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcripts'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Text('All transcripts', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Saved recordings and editable transcript drafts live here.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (controller.transcripts.isEmpty)
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'No transcripts yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Stop a recording first. A draft transcript will be created automatically and can be edited here.',
                  ),
                ],
              ),
            ),
          ...controller.transcripts.map((TranscriptItem transcript) {
            final String firstLine = transcript.segments.isNotEmpty ? transcript.segments.first.text : 'No text yet';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  controller.selectTranscript(transcript);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TranscriptDetailScreen(),
                    ),
                  );
                },
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(transcript.title, style: theme.textTheme.titleLarge),
                                const SizedBox(height: 6),
                                Text(
                                  '${formatDateTime(transcript.updatedAt)} - ${transcript.segments.length} segments',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SpeakerChip(label: 'Editable', index: 0),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        firstLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

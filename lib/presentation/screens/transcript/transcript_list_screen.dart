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
        title: const Text('\uB179\uC74C'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Text('\uBAA8\uB4E0 \uB179\uC74C', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '\uC800\uC7A5\uB41C \uB179\uC74C\uACFC \uC218\uC815 \uAC00\uB2A5\uD55C \uB179\uC74C \uCD08\uC548\uC774 \uC5EC\uAE30\uC5D0 \uB9F5\uB2C8\uB2E4.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (controller.transcripts.isEmpty)
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '\uC544\uC9C1 \uB179\uC74C\uC774 \uC5C6\uC2B5\uB2C8\uB2E4',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '\uBA3C\uC800 \uB179\uC74C\uC744 \uC885\uB8CC\uD574 \uC8FC\uC138\uC694. \uC790\uB3D9\uC73C\uB85C \uB179\uC74C \uCD08\uC548\uC774 \uB9CC\uB4E4\uC5B4\uC9D1\uB2C8\uB2E4.',
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

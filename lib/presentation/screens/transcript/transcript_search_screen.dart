import 'package:flutter/material.dart';

import '../../../app_state/app_scope.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transcript_item.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/speaker_chip.dart';
import 'transcript_detail_screen.dart';

class TranscriptSearchScreen extends StatefulWidget {
  const TranscriptSearchScreen({super.key});

  @override
  State<TranscriptSearchScreen> createState() => _TranscriptSearchScreenState();
}

class _TranscriptSearchScreenState extends State<TranscriptSearchScreen> {
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final String query = _queryController.text.trim().toLowerCase();

    final List<_SearchHit> hits = <_SearchHit>[];
    if (query.isNotEmpty) {
      for (final TranscriptItem transcript in controller.transcripts) {
        if (_matches(transcript.title, query)) {
          hits.add(_SearchHit(transcript: transcript, label: '\uC81C\uBAA9 \uB9E4\uCE6D', excerpt: transcript.title));
        }
        if (_matches(transcript.summary ?? '', query)) {
          hits.add(
            _SearchHit(
              transcript: transcript,
              label: '\uC694\uC57D \uB9E4\uCE6D',
              excerpt: transcript.summary ?? '',
            ),
          );
        }
        for (final segment in transcript.segments) {
          if (_matches(segment.text, query)) {
            hits.add(
              _SearchHit(
                transcript: transcript,
                label: '${segment.speaker} - ${formatRange(segment.startSeconds, segment.endSeconds)}',
                excerpt: segment.text,
              ),
            );
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('\uAC80\uC0C9')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              labelText: '\uB179\uC74C \uAC80\uC0C9',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          Text(
            query.isEmpty ? '\uC81C\uBAA9, \uC694\uC57D, \uB0B4\uC6A9 \uC804\uCCB4\uC5D0\uC11C \uB2E8\uC5B4\uB97C \uAC80\uC0C9\uD558\uC138\uC694.' : '${hits.length}\uAC1C \uACB0\uACFC',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (hits.isEmpty)
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '\uC544\uC9C1 \uB9E4\uCE6D\uB418\uC9C0 \uC54A\uC558\uC2B5\uB2C8\uB2E4',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '\uAC80\uC0C9\uC740 \uB179\uC74C \uC81C\uBAA9\uACFC \uAD6C\uAC04 \uB0B4\uC6A9\uC744 \uD655\uC778\uD569\uB2C8\uB2E4. \uC81C\uBAA9 \uC77C\uBD80 \uB610\uB294 \uBB38\uC7A5 \uD558\uB098\uB85C \uC2DC\uB3C4\uD574 \uBCF4\uC138\uC694.',
                  ),
                ],
              ),
            ),
          ...hits.map((_SearchHit hit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  controller.selectTranscript(hit.transcript);
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
                                _HighlightedText(
                                  text: hit.transcript.title,
                                  query: query,
                                  baseStyle: theme.textTheme.titleLarge ?? const TextStyle(),
                                ),
                                const SizedBox(height: 6),
                                Text(hit.label, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const SpeakerChip(label: '\uB9E4\uCE6D', index: 2),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _HighlightedText(
                        text: hit.excerpt,
                        query: query,
                        baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
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

  bool _matches(String value, String query) {
    if (query.isEmpty) {
      return true;
    }
    return value.toLowerCase().contains(query);
  }
}

class _SearchHit {
  _SearchHit({
    required this.transcript,
    required this.label,
    required this.excerpt,
  });

  final TranscriptItem transcript;
  final String label;
  final String excerpt;
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
  });

  final String text;
  final String query;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final String lowerText = text.toLowerCase();
    final int index = lowerText.indexOf(query);
    if (index == -1) {
      return Text(text, style: baseStyle);
    }

    final TextStyle highlightStyle = baseStyle.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
    );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: <InlineSpan>[
          TextSpan(text: text.substring(0, index)),
          TextSpan(text: text.substring(index, index + query.length), style: highlightStyle),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

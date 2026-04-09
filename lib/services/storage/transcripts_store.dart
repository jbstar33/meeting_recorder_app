import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/transcript_item.dart';

class TranscriptsStore {
  static const String _transcriptsKey = 'transcripts_v1';

  Future<List<TranscriptItem>> loadTranscripts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> rawItems = prefs.getStringList(_transcriptsKey) ?? <String>[];
    return rawItems
        .map((String raw) => TranscriptItem.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((TranscriptItem a, TranscriptItem b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveTranscripts(List<TranscriptItem> transcripts) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> rawItems =
        transcripts.map((TranscriptItem item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_transcriptsKey, rawItems);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/recording_item.dart';

class RecordingsStore {
  static const String _recordingsKey = 'recordings_v1';

  Future<List<RecordingItem>> loadRecordings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> rawItems = prefs.getStringList(_recordingsKey) ?? <String>[];
    return rawItems
        .map((String raw) => RecordingItem.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((RecordingItem a, RecordingItem b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveRecordings(List<RecordingItem> recordings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> rawItems =
        recordings.map((RecordingItem item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_recordingsKey, rawItems);
  }
}

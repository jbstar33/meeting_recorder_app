import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'cloud_stt_models.dart';

class CloudSttService {
  CloudSttService({
    required String apiKey,
    String baseUrl = 'https://api.openai.com/v1',
    String model = 'whisper-1',
  })  : _apiKey = apiKey.trim(),
        _baseUrl = baseUrl.trim().replaceAll(RegExp(r'/$'), ''),
        _model = model.trim();

  String _apiKey;
  final String _baseUrl;
  final String _model;

  bool get isConfigured => _apiKey.isNotEmpty;

  void updateApiKey(String apiKey) {
    _apiKey = apiKey.trim();
  }

  Future<CloudSttResult> transcribeFile(String filePath) async {
    if (!isConfigured) {
      throw StateError('Cloud STT API key is not configured.');
    }

    final File audioFile = File(filePath);
    if (!audioFile.existsSync()) {
      throw StateError('Audio file not found: $filePath');
    }

    final Uri uri = Uri.parse('$_baseUrl/audio/transcriptions');
    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = _model
      ..fields['language'] = 'ko'
      ..fields['response_format'] = 'json'
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final http.StreamedResponse streamed = await request.send();
    final String body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw StateError('Cloud STT failed (${streamed.statusCode}): $body');
    }

    final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
    final String text = (json['text'] as String? ?? '').trim();
    if (text.isEmpty) {
      throw StateError('Cloud STT returned empty text.');
    }
    final String language = (json['language'] as String? ?? 'ko').trim();
    return CloudSttResult(
      text: text,
      language: language.isEmpty ? 'ko' : language,
    );
  }
}

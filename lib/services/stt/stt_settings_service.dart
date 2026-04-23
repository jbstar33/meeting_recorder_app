import 'package:shared_preferences/shared_preferences.dart';

class SttSettingsService {
  SttSettingsService([SharedPreferences? prefs]) : _prefs = prefs;

  static const String _apiKeyField = 'openai_api_key';
  static const String _sttEngineField = 'stt_engine';
  static const String _localPythonCmdField = 'local_python_cmd';
  static const String _localModelField = 'local_whisper_model';
  static const String _localHfTokenField = 'local_hf_token';
  static const String _androidWhisperBinPathField = 'android_whisper_bin_path';
  static const String _androidWhisperModelPathField = 'android_whisper_model_path';
  static const String _androidWhisperBinUrlField = 'android_whisper_bin_url';
  static const String _androidWhisperModelUrlField = 'android_whisper_model_url';
  static const String _defaultAndroidWhisperBinUrl = '';
  static const String _defaultAndroidWhisperModelUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin?download=true';
  final SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs != null) {
      return prefs;
    }
    return SharedPreferences.getInstance();
  }

  Future<String?> loadApiKey() async {
    final SharedPreferences prefs = await _instance();
    final String? value = prefs.getString(_apiKeyField);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<void> saveApiKey(String apiKey) async {
    final SharedPreferences prefs = await _instance();
    await prefs.setString(_apiKeyField, apiKey.trim());
  }

  Future<void> clearApiKey() async {
    final SharedPreferences prefs = await _instance();
    await prefs.remove(_apiKeyField);
  }

  Future<String> loadSttEngine() async {
    final SharedPreferences prefs = await _instance();
    final String value = (prefs.getString(_sttEngineField) ?? 'local').trim().toLowerCase();
    if (value == 'cloud') {
      return 'cloud';
    }
    return 'local';
  }

  Future<void> saveSttEngine(String engine) async {
    final SharedPreferences prefs = await _instance();
    final String normalized = engine.trim().toLowerCase() == 'cloud' ? 'cloud' : 'local';
    await prefs.setString(_sttEngineField, normalized);
  }

  Future<String> loadLocalPythonCommand() async {
    final SharedPreferences prefs = await _instance();
    final String value = (prefs.getString(_localPythonCmdField) ?? 'python').trim();
    return value.isEmpty ? 'python' : value;
  }

  Future<void> saveLocalPythonCommand(String command) async {
    final SharedPreferences prefs = await _instance();
    final String normalized = command.trim();
    await prefs.setString(_localPythonCmdField, normalized.isEmpty ? 'python' : normalized);
  }

  Future<String> loadLocalModel() async {
    final SharedPreferences prefs = await _instance();
    final String value = (prefs.getString(_localModelField) ?? 'small').trim();
    return value.isEmpty ? 'small' : value;
  }

  Future<void> saveLocalModel(String model) async {
    final SharedPreferences prefs = await _instance();
    final String normalized = model.trim();
    await prefs.setString(_localModelField, normalized.isEmpty ? 'small' : normalized);
  }

  Future<String?> loadLocalHfToken() async {
    final SharedPreferences prefs = await _instance();
    final String? value = prefs.getString(_localHfTokenField);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<void> saveLocalHfToken(String? token) async {
    final SharedPreferences prefs = await _instance();
    final String normalized = (token ?? '').trim();
    if (normalized.isEmpty) {
      await prefs.remove(_localHfTokenField);
      return;
    }
    await prefs.setString(_localHfTokenField, normalized);
  }

  Future<String> loadAndroidWhisperBinPath() async {
    final SharedPreferences prefs = await _instance();
    final String value = (prefs.getString(_androidWhisperBinPathField) ??
            '/data/user/0/com.onestore.meeting_recorder_app/files/whisper-cli')
        .trim();
    return value.isEmpty
        ? '/data/user/0/com.onestore.meeting_recorder_app/files/whisper-cli'
        : value;
  }

  Future<void> saveAndroidWhisperBinPath(String path) async {
    final SharedPreferences prefs = await _instance();
    final String normalized = path.trim();
    await prefs.setString(
      _androidWhisperBinPathField,
      normalized.isEmpty
          ? '/data/user/0/com.onestore.meeting_recorder_app/files/whisper-cli'
          : normalized,
    );
  }

  Future<String> loadAndroidWhisperModelPath() async {
    final SharedPreferences prefs = await _instance();
    final String value = (prefs.getString(_androidWhisperModelPathField) ??
            '/data/user/0/com.onestore.meeting_recorder_app/files/models/ggml-base.bin')
        .trim();
    return value.isEmpty
        ? '/data/user/0/com.onestore.meeting_recorder_app/files/models/ggml-base.bin'
        : value;
  }

  Future<void> saveAndroidWhisperModelPath(String path) async {
    final SharedPreferences prefs = await _instance();
    final String normalized = path.trim();
    await prefs.setString(
      _androidWhisperModelPathField,
      normalized.isEmpty
          ? '/data/user/0/com.onestore.meeting_recorder_app/files/models/ggml-base.bin'
          : normalized,
    );
  }

  Future<String> loadAndroidWhisperBinUrl() async {
    final SharedPreferences prefs = await _instance();
    final String value = (prefs.getString(_androidWhisperBinUrlField) ?? _defaultAndroidWhisperBinUrl).trim();
    return value.isEmpty ? _defaultAndroidWhisperBinUrl : value;
  }

  Future<void> saveAndroidWhisperBinUrl(String url) async {
    final SharedPreferences prefs = await _instance();
    final String normalized = url.trim();
    await prefs.setString(
      _androidWhisperBinUrlField,
      normalized.isEmpty ? _defaultAndroidWhisperBinUrl : normalized,
    );
  }

  Future<String> loadAndroidWhisperModelUrl() async {
    final SharedPreferences prefs = await _instance();
    final String value =
        (prefs.getString(_androidWhisperModelUrlField) ?? _defaultAndroidWhisperModelUrl).trim();
    return value.isEmpty ? _defaultAndroidWhisperModelUrl : value;
  }

  Future<void> saveAndroidWhisperModelUrl(String url) async {
    final SharedPreferences prefs = await _instance();
    final String normalized = url.trim();
    await prefs.setString(
      _androidWhisperModelUrlField,
      normalized.isEmpty ? _defaultAndroidWhisperModelUrl : normalized,
    );
  }
}

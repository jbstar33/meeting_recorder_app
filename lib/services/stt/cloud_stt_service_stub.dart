import 'cloud_stt_models.dart';

class CloudSttService {
  const CloudSttService({
    required String apiKey,
    String baseUrl = 'https://api.openai.com/v1',
    String model = 'whisper-1',
  });

  bool get isConfigured => false;

  void updateApiKey(String apiKey) {}

  Future<CloudSttResult> transcribeFile(String filePath) {
    throw UnsupportedError('Cloud STT is not supported on this platform.');
  }
}

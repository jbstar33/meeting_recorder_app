import 'local_stt_models.dart';

class LocalSttService {
  const LocalSttService();

  bool get isSupported => false;

  Future<LocalSttResult> transcribeAndDiarize({
    required String filePath,
    required String pythonCommand,
    required String model,
    String? hfToken,
    String? androidWhisperBinPath,
    String? androidWhisperModelPath,
  }) {
    throw UnsupportedError('Local STT is not supported on this platform.');
  }
}

class AndroidLocalSttSetupService {
  const AndroidLocalSttSetupService();

  bool get isSupported => false;
  Stream<Map<String, dynamic>> get progressStream => const Stream<Map<String, dynamic>>.empty();

  Future<Map<String, String>> installFromUrls({
    required String whisperBinUrl,
    required String modelUrl,
    required String whisperBinPath,
    required String modelPath,
  }) {
    throw UnsupportedError('Android local setup is not supported on this platform.');
  }

  Future<Map<String, String>> installBundledWhisperAndModel({
    required String modelUrl,
    required String whisperBinPath,
    required String modelPath,
  }) {
    throw UnsupportedError('Android local setup is not supported on this platform.');
  }

  Future<bool> verifySetup({
    required String whisperBinPath,
    required String modelPath,
  }) {
    return Future<bool>.value(false);
  }
}

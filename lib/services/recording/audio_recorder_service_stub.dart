class AudioRecorderService {
  Future<bool> hasPermission() async => false;

  Future<bool> requestPermission() async => false;

  Future<String> start() {
    throw UnsupportedError('Recording is not supported on this platform.');
  }

  Future<void> pause() async {}

  Future<void> resume() async {}

  Future<String?> stop() async => null;

  Future<void> dispose() async {}
}

import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

import 'package:record/record.dart';

class AudioRecorderService {
  AudioRecorderService([AudioRecorder? recorder]) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _activePath;

  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  Future<bool> requestPermission() async {
    try {
      final html.MediaStream? stream = await html.window.navigator.mediaDevices?.getUserMedia(
        <String, dynamic>{'audio': true},
      );
      stream?.getTracks().forEach((html.MediaStreamTrack track) => track.stop());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> start() async {
    const String path = 'web_recording.webm';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _activePath = path;
    return path;
  }

  Future<void> pause() => _recorder.pause();

  Future<void> resume() => _recorder.resume();

  Future<String?> stop() async {
    try {
      final String? result = await _recorder.stop().timeout(const Duration(seconds: 5));
      if (result == null || result.isEmpty) {
        return _activePath;
      }
      return await _toPersistableDataUri(result);
    } catch (_) {
      return _activePath;
    } finally {
      _activePath = null;
    }
  }

  Future<String> _toPersistableDataUri(String source) async {
    try {
      final dynamic response = await html.HttpRequest.request(
        source,
        method: 'GET',
        responseType: 'arraybuffer',
      );
      final ByteBuffer? buffer = response.response as ByteBuffer?;
      if (buffer == null) {
        return source;
      }
      final Uint8List bytes = Uint8List.view(buffer);
      final String base64 = base64Encode(bytes);
      return 'data:audio/webm;base64,$base64';
    } catch (_) {
      return source;
    }
  }

  Future<void> dispose() => _recorder.dispose();
}

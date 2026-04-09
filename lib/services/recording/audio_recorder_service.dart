import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  AudioRecorderService([AudioRecorder? recorder]) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }

  Future<String> start() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory recordingsDir = Directory('${appDir.path}${Platform.pathSeparator}recordings');
    if (!recordingsDir.existsSync()) {
      recordingsDir.createSync(recursive: true);
    }

    final DateTime now = DateTime.now();
    final String fileName =
        'meeting_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}.m4a';
    final String path = '${recordingsDir.path}${Platform.pathSeparator}$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    return path;
  }

  Future<void> pause() => _recorder.pause();

  Future<void> resume() => _recorder.resume();

  Future<String?> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();

  String _pad(int value) => value.toString().padLeft(2, '0');
}

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

    final bool isAndroid = Platform.isAndroid;
    final bool isWindows = Platform.isWindows;
    final bool useWavFile = isAndroid || isWindows;
    final String extension = useWavFile ? 'wav' : 'm4a';
    final DateTime now = DateTime.now();
    final String fileName =
        'meeting_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}.$extension';
    final String path = '${recordingsDir.path}${Platform.pathSeparator}$fileName';

    final RecordConfig config = isAndroid
        ? const RecordConfig(
            // Android STT/재생 호환을 위해 WAV 컨테이너로 직접 저장한다.
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          )
        : isWindows
        ? const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          )
        : const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 16000,
            numChannels: 1,
          );

    await _recorder.start(config, path: path);
    return path;
  }

  Future<void> pause() => _recorder.pause();

  Future<void> resume() => _recorder.resume();

  Future<String?> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();

  String _pad(int value) => value.toString().padLeft(2, '0');
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'local_stt_models.dart';

class LocalSttService {
  const LocalSttService();

  static const MethodChannel _androidChannel = MethodChannel('meeting_recorder/local_stt');

  bool get isSupported =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid;

  Future<LocalSttResult> transcribeAndDiarize({
    required String filePath,
    required String pythonCommand,
    required String model,
    String? hfToken,
    String? androidWhisperBinPath,
    String? androidWhisperModelPath,
  }) async {
    if (Platform.isAndroid) {
      return _transcribeOnAndroid(
        filePath: filePath,
        modelPath: androidWhisperModelPath,
        whisperBinPath: androidWhisperBinPath,
      );
    }

    final File audioFile = File(filePath);
    if (!audioFile.existsSync()) {
      throw StateError('녹음 파일을 찾을 수 없습니다: $filePath');
    }

    final String scriptPath = _resolveScriptPath();
    final List<String> args = <String>[
      scriptPath,
      '--input',
      audioFile.path,
      '--model',
      model.trim().isEmpty ? 'small' : model.trim(),
      '--language',
      'ko',
      '--json',
    ];

    final String token = (hfToken ?? '').trim();
    if (token.isNotEmpty) {
      args.addAll(<String>['--hf-token', token]);
    }

    final ProcessResult result = await Process.run(
      pythonCommand.trim().isEmpty ? 'python' : pythonCommand.trim(),
      args,
      runInShell: true,
    ).timeout(const Duration(minutes: 20));

    final String stdoutText = (result.stdout ?? '').toString().trim();
    final String stderrText = (result.stderr ?? '').toString().trim();
    if (result.exitCode != 0) {
      throw StateError(
        '로컬 STT 실행 실패(exit=${result.exitCode}). ${stderrText.isNotEmpty ? stderrText : stdoutText}',
      );
    }

    if (stdoutText.isEmpty) {
      throw StateError('로컬 STT 결과가 비어 있습니다.');
    }

    final Map<String, dynamic> json = jsonDecode(stdoutText) as Map<String, dynamic>;
    final String text = (json['text'] as String? ?? '').trim();
    if (text.isEmpty) {
      throw StateError('로컬 STT 텍스트가 비어 있습니다.');
    }

    final String language = (json['language'] as String? ?? 'ko').trim();
    final List<dynamic> rawSegments = (json['segments'] as List<dynamic>? ?? <dynamic>[]);
    final List<LocalSttSegment> segments = rawSegments
        .map((dynamic item) => item as Map<String, dynamic>)
        .map(
          (Map<String, dynamic> segment) => LocalSttSegment(
            speaker: (segment['speaker'] as String? ?? 'SPEAKER_00').trim(),
            startSeconds: (segment['start'] as num?)?.toInt() ?? 0,
            endSeconds: (segment['end'] as num?)?.toInt() ?? 0,
            text: (segment['text'] as String? ?? '').trim(),
          ),
        )
        .where((LocalSttSegment item) => item.text.isNotEmpty)
        .toList();

    final List<LocalSttSegment> normalizedSegments = segments.isEmpty
        ? <LocalSttSegment>[
            LocalSttSegment(
              speaker: 'SPEAKER_00',
              startSeconds: 0,
              endSeconds: 0,
              text: text,
            ),
          ]
        : segments;

    return LocalSttResult(
      text: text,
      language: language.isEmpty ? 'ko' : language,
      segments: normalizedSegments,
    );
  }

  Future<LocalSttResult> _transcribeOnAndroid({
    required String filePath,
    String? whisperBinPath,
    String? modelPath,
  }) async {
    final String lowerPath = filePath.toLowerCase();
    if (!lowerPath.endsWith('.wav')) {
      throw StateError(
        '안드로이드 내장 STT는 현재 WAV 녹음 파일만 지원합니다. '
        '기존 m4a 파일은 변환이 어려우므로 새로 녹음해서 시도해 주세요.',
      );
    }

    final Map<dynamic, dynamic>? response =
        await _androidChannel.invokeMethod<Map<dynamic, dynamic>>(
      'transcribe',
      <String, dynamic>{
        'filePath': filePath,
        'whisperBinPath': (whisperBinPath ?? '').trim(),
        'modelPath': (modelPath ?? '').trim(),
        'language': 'ko',
      },
    );

    if (response == null) {
      throw StateError('안드로이드 로컬 STT 결과가 비어 있습니다.');
    }

    final String language = (response['language'] as String? ?? 'ko').trim();
    final List<dynamic> rawSegments = (response['segments'] as List<dynamic>? ?? <dynamic>[]);
    final List<LocalSttSegment> segments = rawSegments
        .map((dynamic item) => item as Map<dynamic, dynamic>)
        .map(
          (Map<dynamic, dynamic> segment) => LocalSttSegment(
            speaker: (segment['speaker'] as String? ?? 'SPEAKER_00').trim(),
            startSeconds: (segment['start'] as num?)?.toInt() ?? 0,
            endSeconds: (segment['end'] as num?)?.toInt() ?? 0,
            text: (segment['text'] as String? ?? '').trim(),
          ),
        )
        .where((LocalSttSegment item) => item.text.isNotEmpty)
        .toList();

    final String responseText = (response['text'] as String? ?? '').trim();
    final String mergedSegmentsText = segments.map((LocalSttSegment item) => item.text).join(' ').trim();
    final String text = responseText.isNotEmpty ? responseText : mergedSegmentsText;
    if (text.isEmpty) {
      throw StateError('안드로이드 로컬 STT 텍스트가 비어 있습니다.');
    }

    return LocalSttResult(
      text: text,
      language: language.isEmpty ? 'ko' : language,
      segments: segments.isEmpty
          ? <LocalSttSegment>[
              LocalSttSegment(
                speaker: 'SPEAKER_00',
                startSeconds: 0,
                endSeconds: 0,
                text: text,
              ),
            ]
          : segments,
    );
  }

  String _resolveScriptPath() {
    final List<String> candidates = <String>[
      '${Directory.current.path}${Platform.pathSeparator}tools${Platform.pathSeparator}local_stt${Platform.pathSeparator}transcribe_diarize.py',
      '${Directory.current.path}${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}tools${Platform.pathSeparator}local_stt${Platform.pathSeparator}transcribe_diarize.py',
    ];

    for (final String candidate in candidates) {
      final File file = File(candidate);
      if (file.existsSync()) {
        return file.path;
      }
    }
    throw StateError('로컬 STT 스크립트를 찾을 수 없습니다. tools/local_stt/transcribe_diarize.py');
  }
}

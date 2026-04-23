import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';

class AndroidLocalSttSetupService {
  const AndroidLocalSttSetupService();

  static const MethodChannel _channel = MethodChannel('meeting_recorder/local_stt');
  static final StreamController<Map<String, dynamic>> _progressController =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _isHandlerAttached = false;

  bool get isSupported => Platform.isAndroid;
  Stream<Map<String, dynamic>> get progressStream {
    _ensureHandler();
    return _progressController.stream;
  }

  void _ensureHandler() {
    if (_isHandlerAttached) {
      return;
    }
    _isHandlerAttached = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'installProgress') {
        final Map<dynamic, dynamic> raw = (call.arguments as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{});
        _progressController.add(<String, dynamic>{
          'step': (raw['step'] ?? '').toString(),
          'progress': (raw['progress'] as num?)?.toInt() ?? 0,
          'message': (raw['message'] ?? '').toString(),
        });
      }
    });
  }

  Future<Map<String, String>> installFromUrls({
    required String whisperBinUrl,
    required String modelUrl,
    required String whisperBinPath,
    required String modelPath,
  }) async {
    _ensureHandler();
    if (!Platform.isAndroid) {
      throw UnsupportedError('Android local setup is supported only on Android.');
    }
    final Map<dynamic, dynamic>? response =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'installFromUrls',
      <String, dynamic>{
        'whisperBinUrl': whisperBinUrl,
        'modelUrl': modelUrl,
        'whisperBinPath': whisperBinPath,
        'modelPath': modelPath,
      },
    );
    if (response == null) {
      throw StateError('설치 결과가 비어 있습니다.');
    }
    return <String, String>{
      'whisperBinPath': (response['whisperBinPath'] as String? ?? '').trim(),
      'modelPath': (response['modelPath'] as String? ?? '').trim(),
    };
  }

  Future<Map<String, String>> installBundledWhisperAndModel({
    required String modelUrl,
    required String whisperBinPath,
    required String modelPath,
  }) async {
    _ensureHandler();
    if (!Platform.isAndroid) {
      throw UnsupportedError('Android local setup is supported only on Android.');
    }
    final Map<dynamic, dynamic>? response =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'installBundledWhisperAndModel',
      <String, dynamic>{
        'modelUrl': modelUrl,
        'whisperBinPath': whisperBinPath,
        'modelPath': modelPath,
      },
    );
    if (response == null) {
      throw StateError('?ㅼ튂 寃곌낵媛 鍮꾩뼱 ?덉뒿?덈떎.');
    }
    return <String, String>{
      'whisperBinPath': (response['whisperBinPath'] as String? ?? '').trim(),
      'modelPath': (response['modelPath'] as String? ?? '').trim(),
    };
  }

  Future<bool> verifySetup({
    required String whisperBinPath,
    required String modelPath,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }
    final bool? ok = await _channel.invokeMethod<bool>(
      'verifySetup',
      <String, dynamic>{
        'whisperBinPath': whisperBinPath,
        'modelPath': modelPath,
      },
    );
    return ok ?? false;
  }
}

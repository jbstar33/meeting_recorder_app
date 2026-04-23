import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/recording_item.dart';
import '../data/models/session_state.dart';
import '../data/models/transcript_item.dart';
import '../services/export/transcript_export_service.dart';
import '../services/recording/audio_recorder_service.dart';
import '../services/security/pin_service.dart';
import '../services/storage/recordings_store.dart';
import '../services/storage/transcripts_store.dart';
import '../services/stt/cloud_stt_models.dart';
import '../services/stt/cloud_stt_service.dart';
import '../services/stt/android_local_stt_setup_service.dart';
import '../services/stt/local_stt_models.dart';
import '../services/stt/local_stt_service.dart';
import '../services/stt/stt_settings_service.dart';

class AppController extends ChangeNotifier {
  static const String _defaultAndroidWhisperBinUrl =
      '';
  static const String _defaultAndroidWhisperModelUrl =
      '';

  AppController({
    required PinService pinService,
    required RecordingsStore recordingsStore,
    required TranscriptsStore transcriptsStore,
    required TranscriptExportService exportService,
    required AudioRecorderService recorderService,
    required CloudSttService cloudSttService,
    required LocalSttService localSttService,
    required AndroidLocalSttSetupService androidLocalSttSetupService,
    required SttSettingsService sttSettingsService,
  })  : _pinService = pinService,
        _recordingsStore = recordingsStore,
        _transcriptsStore = transcriptsStore,
        _exportService = exportService,
        _recorderService = recorderService,
        _cloudSttService = cloudSttService,
        _localSttService = localSttService,
        _androidLocalSttSetupService = androidLocalSttSetupService,
        _sttSettingsService = sttSettingsService;

  final PinService _pinService;
  final RecordingsStore _recordingsStore;
  final TranscriptsStore _transcriptsStore;
  final TranscriptExportService _exportService;
  final AudioRecorderService _recorderService;
  final CloudSttService _cloudSttService;
  final LocalSttService _localSttService;
  final AndroidLocalSttSetupService _androidLocalSttSetupService;
  final SttSettingsService _sttSettingsService;

  AuthState authState = AuthState.loading;
  RecordingPhase recordingPhase = RecordingPhase.idle;
  List<RecordingItem> recordings = <RecordingItem>[];
  List<TranscriptItem> transcripts = <TranscriptItem>[];
  RecordingItem? selectedRecording;
  TranscriptItem? selectedTranscript;
  String? activeRecordingPath;
  String? authError;
  String? recordingError;
  String? transcriptionError;
  bool microphonePermissionGranted = false;
  String? sttApiKeyPreview;
  String sttEngine = 'local';
  String localPythonCommand = 'python';
  String localModel = 'small';
  String androidWhisperBinPath =
      '/data/user/0/com.onestore.meeting_recorder_app/files/whisper-cli';
  String androidWhisperModelPath =
      '/data/user/0/com.onestore.meeting_recorder_app/files/models/ggml-base.bin';
  String androidWhisperBinUrl = _defaultAndroidWhisperBinUrl;
  String androidWhisperModelUrl = _defaultAndroidWhisperModelUrl;
  String? localHfTokenPreview;
  bool isTranscribing = false;
  bool isInstallingLocalStt = false;
  int localSttInstallProgress = 0;
  String localSttInstallMessage = '';
  int recordingSeconds = 0;
  Timer? _ticker;

  Future<void> bootstrap() async {
    final bool hasPin = await _pinService.hasPin();
    final String? savedApiKey = await _sttSettingsService.loadApiKey();
    if (savedApiKey != null) {
      _cloudSttService.updateApiKey(savedApiKey);
      sttApiKeyPreview = _maskApiKey(savedApiKey);
    }
    sttEngine = await _sttSettingsService.loadSttEngine();
    localPythonCommand = await _sttSettingsService.loadLocalPythonCommand();
    localModel = await _sttSettingsService.loadLocalModel();
    androidWhisperBinPath = await _sttSettingsService.loadAndroidWhisperBinPath();
    androidWhisperModelPath = await _sttSettingsService.loadAndroidWhisperModelPath();
    androidWhisperBinUrl = await _sttSettingsService.loadAndroidWhisperBinUrl();
    androidWhisperModelUrl = await _sttSettingsService.loadAndroidWhisperModelUrl();
    final String? localHfToken = await _sttSettingsService.loadLocalHfToken();
    localHfTokenPreview = localHfToken == null ? null : _maskApiKey(localHfToken);
    microphonePermissionGranted = await _safeHasMicrophonePermission();
    recordings = await _recordingsStore.loadRecordings();
    transcripts = await _transcriptsStore.loadTranscripts();
    authState = hasPin ? AuthState.locked : AuthState.needsPinSetup;
    notifyListeners();
  }

  Future<bool> createPin(String first, String second) async {
    authError = null;
    if (first.length != 4 || second.length != 4) {
      authError = '비밀번호는 4자리여야 합니다.';
      notifyListeners();
      return false;
    }
    if (first != second) {
      authError = '비밀번호가 서로 다릅니다.';
      notifyListeners();
      return false;
    }
    await _pinService.savePin(first);
    authState = AuthState.unlocked;
    notifyListeners();
    return true;
  }

  Future<bool> unlock(String pin) async {
    authError = null;
    final bool isValid = await _pinService.verifyPin(pin);
    if (!isValid) {
      authError = '비밀번호가 틀렸습니다. 다시 입력해 주세요.';
      notifyListeners();
      return false;
    }
    authState = AuthState.unlocked;
    notifyListeners();
    return true;
  }

  void lock() {
    authState = AuthState.locked;
    notifyListeners();
  }

  void selectRecording(RecordingItem item) {
    selectedRecording = item;
    selectedTranscript = _transcriptForRecordingId(item.id);
    notifyListeners();
  }

  void selectTranscript(TranscriptItem item) {
    selectedTranscript = item;
    selectedRecording = _recordingForId(item.recordingId);
    notifyListeners();
  }

  Future<void> updateTranscriptMetadata({
    required String transcriptId,
    String? title,
    String? summary,
  }) async {
    final int transcriptIndex =
        transcripts.indexWhere((TranscriptItem transcript) => transcript.id == transcriptId);
    if (transcriptIndex == -1) {
      return;
    }

    final TranscriptItem transcript = transcripts[transcriptIndex];
    final TranscriptItem updated = transcript.copyWith(
      title: title ?? transcript.title,
      summary: summary ?? transcript.summary,
      updatedAt: DateTime.now(),
    );
    transcripts[transcriptIndex] = updated;
    if (selectedTranscript?.id == transcriptId) {
      selectedTranscript = updated;
    }
    await _transcriptsStore.saveTranscripts(transcripts);
    notifyListeners();
  }

  Future<void> deleteTranscript(String transcriptId) async {
    final TranscriptItem? transcript = _transcriptForId(transcriptId);
    if (transcript == null) {
      return;
    }

    transcripts = transcripts.where((TranscriptItem item) => item.id != transcriptId).toList();
    if (selectedTranscript?.id == transcriptId) {
      selectedTranscript = null;
    }
    if (selectedRecording?.id == transcript.recordingId) {
      selectedRecording = null;
    }
    await _transcriptsStore.saveTranscripts(transcripts);
    notifyListeners();
  }

  Future<String?> exportTranscript(String transcriptId) async {
    final TranscriptItem? transcript = _transcriptForId(transcriptId);
    if (transcript == null) {
      return null;
    }

    final RecordingItem? recording = _recordingForId(transcript.recordingId);
    return _exportService.exportMarkdown(transcript, recording: recording);
  }

  Future<void> retryTranscription(String transcriptId) async {
    final TranscriptItem? transcript = _transcriptForId(transcriptId);
    if (transcript == null) {
      return;
    }
    final RecordingItem? recording = _recordingForId(transcript.recordingId);
    if (recording == null) {
      return;
    }
    await _runSelectedTranscription(recording.id, transcript.id);
  }

  Future<void> saveSttApiKey(String apiKey) async {
    final String normalized = apiKey.trim();
    if (normalized.isEmpty) {
      await clearSttApiKey();
      return;
    }
    await _sttSettingsService.saveApiKey(normalized);
    _cloudSttService.updateApiKey(normalized);
    sttApiKeyPreview = _maskApiKey(normalized);
    transcriptionError = null;
    notifyListeners();
  }

  Future<void> clearSttApiKey() async {
    await _sttSettingsService.clearApiKey();
    _cloudSttService.updateApiKey('');
    sttApiKeyPreview = null;
    notifyListeners();
  }

  Future<void> saveSttEngine(String engine) async {
    final String requested = engine.trim().toLowerCase() == 'cloud' ? 'cloud' : 'local';
    final String normalized = requested == 'local' && !isLocalSttAvailable ? 'cloud' : requested;
    sttEngine = normalized;
    await _sttSettingsService.saveSttEngine(sttEngine);
    if (requested == 'local' && !isLocalSttAvailable) {
      transcriptionError = '로컬 STT는 모바일에서 지원되지 않아 클라우드 엔진으로 전환했습니다.';
    }
    notifyListeners();
  }

  Future<void> saveLocalSttConfig({
    required String pythonCommand,
    required String model,
    String? hfToken,
    String? androidBinPath,
    String? androidModelPath,
    String? androidBinUrl,
    String? androidModelUrl,
  }) async {
    final String normalizedPython = pythonCommand.trim().isEmpty ? 'python' : pythonCommand.trim();
    final String normalizedModel = model.trim().isEmpty ? 'small' : model.trim();
    final String? normalizedToken = (hfToken ?? '').trim().isEmpty ? null : hfToken!.trim();
    final String normalizedAndroidBin = (androidBinPath ?? '').trim().isEmpty
        ? '/data/user/0/com.onestore.meeting_recorder_app/files/whisper-cli'
        : androidBinPath!.trim();
    final String normalizedAndroidModel = (androidModelPath ?? '').trim().isEmpty
        ? '/data/user/0/com.onestore.meeting_recorder_app/files/models/ggml-base.bin'
        : androidModelPath!.trim();
    final String normalizedAndroidBinUrl = (androidBinUrl ?? '').trim().isEmpty
        ? _defaultAndroidWhisperBinUrl
        : androidBinUrl!.trim();
    final String normalizedAndroidModelUrl = (androidModelUrl ?? '').trim().isEmpty
        ? _defaultAndroidWhisperModelUrl
        : androidModelUrl!.trim();

    await _sttSettingsService.saveLocalPythonCommand(normalizedPython);
    await _sttSettingsService.saveLocalModel(normalizedModel);
    await _sttSettingsService.saveLocalHfToken(normalizedToken);
    await _sttSettingsService.saveAndroidWhisperBinPath(normalizedAndroidBin);
    await _sttSettingsService.saveAndroidWhisperModelPath(normalizedAndroidModel);
    await _sttSettingsService.saveAndroidWhisperBinUrl(normalizedAndroidBinUrl);
    await _sttSettingsService.saveAndroidWhisperModelUrl(normalizedAndroidModelUrl);

    localPythonCommand = normalizedPython;
    localModel = normalizedModel;
    androidWhisperBinPath = normalizedAndroidBin;
    androidWhisperModelPath = normalizedAndroidModel;
    androidWhisperBinUrl = normalizedAndroidBinUrl;
    androidWhisperModelUrl = normalizedAndroidModelUrl;
    localHfTokenPreview = normalizedToken == null ? null : _maskApiKey(normalizedToken);
    notifyListeners();
  }

  Future<bool> installAndroidLocalSttFromUrls() async {
    if (!_androidLocalSttSetupService.isSupported) {
      transcriptionError = '이 기능은 안드로이드에서만 사용할 수 있습니다.';
      notifyListeners();
      return false;
    }
    final String binUrl = androidWhisperBinUrl.trim();
    final String modelUrl = androidWhisperModelUrl.trim();
    if ((modelUrl.isNotEmpty && !_isValidDownloadUrl(modelUrl)) ||
        (binUrl.isNotEmpty && !_isValidDownloadUrl(binUrl))) {
      transcriptionError = 'URL 형식이 올바르지 않습니다. https://로 시작하는 직접 다운로드 링크를 입력해 주세요.';
      notifyListeners();
      return false;
    }
    if ((binUrl.isNotEmpty && binUrl.contains('...')) || (modelUrl.isNotEmpty && modelUrl.contains('...'))) {
      transcriptionError = '예시 URL(… 포함)이 입력되어 있습니다. 실제 전체 다운로드 URL을 넣어 주세요.';
      notifyListeners();
      return false;
    }

    isInstallingLocalStt = true;
    localSttInstallProgress = 0;
    localSttInstallMessage = '설치 준비 중...';
    transcriptionError = null;
    notifyListeners();
    final StreamSubscription<Map<String, dynamic>> progressSub =
        _androidLocalSttSetupService.progressStream.listen((Map<String, dynamic> event) {
      localSttInstallProgress = (event['progress'] as int?) ?? 0;
      final String message = (event['message'] as String? ?? '').trim();
      if (message.isNotEmpty) {
        localSttInstallMessage = message;
      }
      notifyListeners();
    });
    try {
      final bool useBundledEngine = binUrl.isEmpty;
      final Map<String, String> installed = useBundledEngine
          ? await _androidLocalSttSetupService.installBundledWhisperAndModel(
              modelUrl: modelUrl,
              whisperBinPath: androidWhisperBinPath,
              modelPath: androidWhisperModelPath,
            )
          : await _androidLocalSttSetupService.installFromUrls(
              whisperBinUrl: binUrl,
              modelUrl: modelUrl,
              whisperBinPath: androidWhisperBinPath,
              modelPath: androidWhisperModelPath,
            );
      if ((installed['whisperBinPath'] ?? '').isNotEmpty) {
        androidWhisperBinPath = installed['whisperBinPath']!;
      }
      if ((installed['modelPath'] ?? '').isNotEmpty) {
        androidWhisperModelPath = installed['modelPath']!;
      }
      await _sttSettingsService.saveAndroidWhisperBinPath(androidWhisperBinPath);
      await _sttSettingsService.saveAndroidWhisperModelPath(androidWhisperModelPath);
      if (sttEngine != 'local') {
        sttEngine = 'local';
        await _sttSettingsService.saveSttEngine('local');
      }
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('LOCAL_STT install failed: $error');
      final String message = error.toString();
      transcriptionError = message.contains('bundled asset missing')
          ? 'APK에 내장된 whisper 자산(엔진 또는 모델)이 없습니다. 자산 포함 후 다시 빌드해 주세요.'
          : 'Android 로컬 STT 설치 실패: $message';
      notifyListeners();
      return false;
    } finally {
      await progressSub.cancel();
      isInstallingLocalStt = false;
      notifyListeners();
    }
  }

  Future<void> refreshMicrophonePermission() async {
    microphonePermissionGranted = await _safeHasMicrophonePermission();
    notifyListeners();
  }

  Future<bool> requestMicrophonePermission() async {
    final bool granted = await _recorderService.requestPermission();
    microphonePermissionGranted = granted || await _safeHasMicrophonePermission();
    notifyListeners();
    return microphonePermissionGranted;
  }

  Future<bool> startRecording() async {
    recordingError = null;
    if (kIsWeb) {
      recordingError = '웹에서는 녹음 기능을 지원하지 않습니다. UI 확인용으로만 사용해 주세요.';
      notifyListeners();
      return false;
    }
    final bool hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      recordingError = '녹음을 시작하려면 마이크 접근 권한이 필요합니다.';
      notifyListeners();
      return false;
    }

    activeRecordingPath = await _recorderService.start();
    recordingSeconds = 0;
    recordingPhase = RecordingPhase.recording;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      recordingSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
    return true;
  }

  Future<void> pauseRecording() async {
    if (recordingPhase != RecordingPhase.recording) {
      return;
    }
    await _recorderService.pause();
    _ticker?.cancel();
    recordingPhase = RecordingPhase.paused;
    notifyListeners();
  }

  Future<void> resumeRecording() async {
    if (recordingPhase != RecordingPhase.paused) {
      return;
    }
    await _recorderService.resume();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      recordingSeconds += 1;
      notifyListeners();
    });
    recordingPhase = RecordingPhase.recording;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (recordingPhase == RecordingPhase.idle || activeRecordingPath == null) {
      return;
    }
    recordingPhase = RecordingPhase.stopping;
    _ticker?.cancel();
    notifyListeners();
    try {
      final String? finalPath = await _recorderService.stop().timeout(const Duration(seconds: 8));
      final DateTime createdAt = DateTime.now();
      final RecordingItem item = RecordingItem(
        id: _newId(),
        title:
            '녹음 ${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
        filePath: finalPath ?? activeRecordingPath!,
        createdAt: createdAt,
        durationSeconds: recordingSeconds,
        status: _willRunTranscription ? '변환 대기' : '저장됨',
        summary: '기기에 녹음이 저장되었습니다. 음성-텍스트 변환과 분석은 다음 단계에서 처리합니다.',
      );
      recordings = <RecordingItem>[item, ...recordings];
      selectedRecording = item;
      final TranscriptItem transcript = _createDraftTranscript(item);
      transcripts = <TranscriptItem>[transcript, ...transcripts];
      selectedTranscript = transcript;
      await _recordingsStore.saveRecordings(recordings);
      await _transcriptsStore.saveTranscripts(transcripts);

      if (_willRunTranscription) {
        unawaited(_runSelectedTranscription(item.id, transcript.id));
      }
    } catch (_) {
      recordingError = '저장이 지연되었습니다. 다시 종료를 시도해 주세요.';
    } finally {
      activeRecordingPath = null;
      recordingSeconds = 0;
      recordingPhase = RecordingPhase.idle;
      notifyListeners();
    }
  }

  Future<void> updateTranscriptSegment({
    required String transcriptId,
    required String segmentId,
    required String newText,
  }) async {
    final int transcriptIndex =
        transcripts.indexWhere((TranscriptItem transcript) => transcript.id == transcriptId);
    if (transcriptIndex == -1) {
      return;
    }

    final TranscriptItem transcript = transcripts[transcriptIndex];
    final List<TranscriptSegment> updatedSegments = transcript.segments.map((TranscriptSegment segment) {
      if (segment.id != segmentId) {
        return segment;
      }
      return segment.copyWith(text: newText);
    }).toList();

    final TranscriptItem updated = transcript.copyWith(
      updatedAt: DateTime.now(),
      segments: updatedSegments,
    );
    transcripts[transcriptIndex] = updated;
    if (selectedTranscript?.id == transcriptId) {
      selectedTranscript = updated;
    }
    await _transcriptsStore.saveTranscripts(transcripts);
    notifyListeners();
  }

  void refreshSelectionFromId(String recordingId) {
    selectedRecording = _recordingForId(recordingId);
    selectedTranscript = _transcriptForRecordingId(recordingId);
    notifyListeners();
  }

  RecordingItem? recordingForTranscript(String transcriptId) {
    final TranscriptItem? transcript = _transcriptForId(transcriptId);
    if (transcript == null) {
      return null;
    }
    return _recordingForId(transcript.recordingId);
  }

  TranscriptItem _createDraftTranscript(RecordingItem item) {
    final DateTime now = DateTime.now();
    final String title = _suggestTranscriptTitle(item);
    final List<TranscriptSegment> segments = <TranscriptSegment>[
      TranscriptSegment(
        id: '${item.id}-s1',
        speaker: 'SPEAKER_00',
        startSeconds: 0,
        endSeconds: min(32, item.durationSeconds),
        text: '이 구간은 음성-텍스트 변환 모델의 예시 문장입니다. 실제 STT 엔진이 연결되면 이 문장은 한국어 대화 내용으로 교체됩니다.',
      ),
    ];

    return TranscriptItem(
      id: 't-${item.id}',
      recordingId: item.id,
      title: title,
      createdAt: now,
      updatedAt: now,
      language: 'ko',
      segments: segments,
      summary: item.summary,
    );
  }

  Future<void> _runCloudTranscription(String recordingId, String transcriptId) async {
    final RecordingItem? recording = _recordingForId(recordingId);
    if (recording == null) {
      return;
    }
    final CloudSttResult result = await _cloudSttService.transcribeFile(recording.filePath);
    final String text = result.text.trim();
    final String summary = _summaryFromText(text);
    final int duration = max(recording.durationSeconds, 1);
    final List<TranscriptSegment> segments = <TranscriptSegment>[
      TranscriptSegment(
        id: '$transcriptId-stt-1',
        speaker: 'SPEAKER_00',
        startSeconds: 0,
        endSeconds: duration,
        text: text,
      ),
    ];

    final int index = transcripts.indexWhere((TranscriptItem t) => t.id == transcriptId);
    if (index != -1) {
      final TranscriptItem updated = transcripts[index].copyWith(
        segments: segments,
        summary: summary,
        language: result.language,
        updatedAt: DateTime.now(),
      );
      transcripts[index] = updated;
      if (selectedTranscript?.id == transcriptId) {
        selectedTranscript = updated;
      }
    }

    _updateRecordingStatus(
      recordingId: recordingId,
      status: '변환 완료',
      summary: summary,
    );
    await _recordingsStore.saveRecordings(recordings);
    await _transcriptsStore.saveTranscripts(transcripts);
  }

  Future<void> _runLocalTranscription(String recordingId, String transcriptId) async {
    final RecordingItem? recording = _recordingForId(recordingId);
    if (recording == null) {
      return;
    }

    if (!_localSttService.isSupported) {
      throw StateError('로컬 STT는 이 플랫폼에서 지원되지 않습니다.');
    }

    if (_androidLocalSttSetupService.isSupported) {
      final bool setupOk = await _androidLocalSttSetupService.verifySetup(
        whisperBinPath: androidWhisperBinPath,
        modelPath: androidWhisperModelPath,
      );
      if (!setupOk) {
        throw StateError('Android 로컬 STT 파일이 준비되지 않았습니다. 설정에서 내장 엔진 설치를 먼저 실행해 주세요.');
      }
    }

    final String? hfToken = await _sttSettingsService.loadLocalHfToken();
    final LocalSttResult result = await _localSttService.transcribeAndDiarize(
      filePath: recording.filePath,
      pythonCommand: localPythonCommand,
      model: localModel,
      hfToken: hfToken,
      androidWhisperBinPath: androidWhisperBinPath,
      androidWhisperModelPath: androidWhisperModelPath,
    );
    final String text = result.text.trim();
    final String summary = _summaryFromText(text);
    final List<TranscriptSegment> segments = result.segments
        .asMap()
        .entries
        .map(
          (MapEntry<int, LocalSttSegment> entry) => TranscriptSegment(
            id: '$transcriptId-local-${entry.key + 1}',
            speaker: entry.value.speaker,
            startSeconds: entry.value.startSeconds,
            endSeconds: entry.value.endSeconds < entry.value.startSeconds
                ? entry.value.startSeconds
                : entry.value.endSeconds,
            text: entry.value.text,
          ),
        )
        .toList();

    final int index = transcripts.indexWhere((TranscriptItem t) => t.id == transcriptId);
    if (index != -1) {
      final TranscriptItem updated = transcripts[index].copyWith(
        segments: segments,
        summary: summary,
        language: result.language,
        updatedAt: DateTime.now(),
      );
      transcripts[index] = updated;
      if (selectedTranscript?.id == transcriptId) {
        selectedTranscript = updated;
      }
    }

    _updateRecordingStatus(
      recordingId: recordingId,
      status: '변환 완료',
      summary: summary,
    );
    await _recordingsStore.saveRecordings(recordings);
    await _transcriptsStore.saveTranscripts(transcripts);
  }

  Future<void> _runSelectedTranscription(String recordingId, String transcriptId) async {
    isTranscribing = true;
    transcriptionError = null;
    _updateRecordingStatus(recordingId: recordingId, status: '변환 중');
    notifyListeners();

    try {
      if (_resolvedSttEngine == 'local') {
        await _runLocalTranscription(recordingId, transcriptId);
      } else if (_resolvedSttEngine == 'cloud') {
        await _runCloudTranscription(recordingId, transcriptId);
      } else {
        throw StateError('사용 가능한 변환 엔진이 없습니다. 설정에서 엔진을 확인해 주세요.');
      }
    } catch (error) {
      transcriptionError = '음성-텍스트 변환이 실패했습니다. ${error.toString()}';
      _updateRecordingStatus(recordingId: recordingId, status: '변환실패');
      await _recordingsStore.saveRecordings(recordings);
    } finally {
      isTranscribing = false;
      notifyListeners();
    }
  }

  void _updateRecordingStatus({
    required String recordingId,
    required String status,
    String? summary,
  }) {
    final int index = recordings.indexWhere((RecordingItem item) => item.id == recordingId);
    if (index == -1) {
      return;
    }
    final RecordingItem current = recordings[index];
    final RecordingItem updated = current.copyWith(
      status: status,
      summary: summary ?? current.summary,
    );
    recordings[index] = updated;
    if (selectedRecording?.id == recordingId) {
      selectedRecording = updated;
    }
  }

  String _summaryFromText(String text) {
    final String compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 140) {
      return compact;
    }
    return '${compact.substring(0, 140)}...';
  }

  bool get hasCloudSttApiKey => _cloudSttService.isConfigured;
  bool get isLocalSttAvailable => _localSttService.isSupported;
  bool get isLocalSttConfigured => localPythonCommand.trim().isNotEmpty;
  String get _resolvedSttEngine {
    if (sttEngine == 'local' && isLocalSttAvailable && isLocalSttConfigured) {
      return 'local';
    }
    if (_cloudSttService.isConfigured) {
      return 'cloud';
    }
    return 'none';
  }

  bool get _willRunTranscription => _resolvedSttEngine != 'none';

  bool _isValidDownloadUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
  }

  Future<bool> _safeHasMicrophonePermission() async {
    try {
      return await _recorderService.hasPermission();
    } catch (_) {
      return false;
    }
  }

  String _maskApiKey(String value) {
    if (value.length <= 8) {
      return '****';
    }
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  String _suggestTranscriptTitle(RecordingItem item) {
    final String month = item.createdAt.month.toString().padLeft(2, '0');
    final String day = item.createdAt.day.toString().padLeft(2, '0');
    final String hour = item.createdAt.hour.toString().padLeft(2, '0');
    final String minute = item.createdAt.minute.toString().padLeft(2, '0');
    return '녹음 $month/$day $hour:$minute';
  }

  RecordingItem? _recordingForId(String id) {
    for (final RecordingItem recording in recordings) {
      if (recording.id == id) {
        return recording;
      }
    }
    return null;
  }

  TranscriptItem? _transcriptForRecordingId(String recordingId) {
    for (final TranscriptItem transcript in transcripts) {
      if (transcript.recordingId == recordingId) {
        return transcript;
      }
    }
    return null;
  }

  TranscriptItem? _transcriptForId(String id) {
    for (final TranscriptItem transcript in transcripts) {
      if (transcript.id == id) {
        return transcript;
      }
    }
    return null;
  }

  String _newId() {
    final Random random = Random();
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int nonce = random.nextInt(1 << 32);
    return '$timestamp-$nonce';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_recorderService.dispose());
    super.dispose();
  }
}

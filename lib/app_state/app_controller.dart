import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/recording_item.dart';
import '../data/models/transcript_item.dart';
import '../data/models/session_state.dart';
import '../services/export/transcript_export_service.dart';
import '../services/recording/audio_recorder_service.dart';
import '../services/security/pin_service.dart';
import '../services/storage/recordings_store.dart';
import '../services/storage/transcripts_store.dart';

class AppController extends ChangeNotifier {
  AppController({
    required PinService pinService,
    required RecordingsStore recordingsStore,
    required TranscriptsStore transcriptsStore,
    required TranscriptExportService exportService,
    required AudioRecorderService recorderService,
  })  : _pinService = pinService,
        _recordingsStore = recordingsStore,
        _transcriptsStore = transcriptsStore,
        _exportService = exportService,
        _recorderService = recorderService;

  final PinService _pinService;
  final RecordingsStore _recordingsStore;
  final TranscriptsStore _transcriptsStore;
  final TranscriptExportService _exportService;
  final AudioRecorderService _recorderService;

  AuthState authState = AuthState.loading;
  RecordingPhase recordingPhase = RecordingPhase.idle;
  List<RecordingItem> recordings = <RecordingItem>[];
  List<TranscriptItem> transcripts = <TranscriptItem>[];
  RecordingItem? selectedRecording;
  TranscriptItem? selectedTranscript;
  String? activeRecordingPath;
  String? authError;
  String? recordingError;
  int recordingSeconds = 0;
  Timer? _ticker;

  Future<void> bootstrap() async {
    final bool hasPin = await _pinService.hasPin();
    recordings = await _recordingsStore.loadRecordings();
    transcripts = await _transcriptsStore.loadTranscripts();
    authState = hasPin ? AuthState.locked : AuthState.needsPinSetup;
    notifyListeners();
  }

  Future<bool> createPin(String first, String second) async {
    authError = null;
    if (first.length != 4 || second.length != 4) {
      authError = '\uBE44\uBC00\uBC88\uD638\uB294 4\uC790\uB9AC\uC5EC\uC57C \uD569\uB2C8\uB2E4.';
      notifyListeners();
      return false;
    }
    if (first != second) {
      authError = '\uBE44\uBC00\uBC88\uD638\uAC00 \uC11C\uB85C \uB2E4\uB985\uB2C8\uB2E4.';
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
      authError = '\uBE44\uBC00\uBC88\uD638\uAC00 \uD2C0\uB838\uC2B5\uB2C8\uB2E4. \uB2E4\uC2DC \uC785\uB825\uD574 \uC8FC\uC138\uC694.';
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

  Future<bool> startRecording() async {
    recordingError = null;
    final bool hasPermission = await _recorderService.requestPermission();
    if (!hasPermission) {
      recordingError = '\uB179\uC74C\uC744 \uC2DC\uC791\uD558\uB824\uBA74 \uB9C8\uC774\uD06C \uC811\uADFC \uAD8C\uD55C\uC774 \uD544\uC694\uD569\uB2C8\uB2E4.';
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

    final String? finalPath = await _recorderService.stop();
    final DateTime createdAt = DateTime.now();
    final RecordingItem item = RecordingItem(
      id: _newId(),
      title:
          '\uB179\uC74C ${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
      filePath: finalPath ?? activeRecordingPath!,
      createdAt: createdAt,
      durationSeconds: recordingSeconds,
      status: '\uC800\uC7A5\uB428',
      summary:
          '\uAE30\uAE30\uC5D0 \uB179\uC74C\uC774 \uC800\uC7A5\uB418\uC5C8\uC2B5\uB2C8\uB2E4. \uC804\uC0AC\uC640 \uBD84\uC11D\uC740 \uB2E4\uC74C \uB2E8\uACC4\uC5D0\uC11C \uCC98\uB9AC\uD569\uB2C8\uB2E4.',
    );
    recordings = <RecordingItem>[item, ...recordings];
    selectedRecording = item;
    final TranscriptItem transcript = _createDraftTranscript(item);
    transcripts = <TranscriptItem>[transcript, ...transcripts];
    selectedTranscript = transcript;
    await _recordingsStore.saveRecordings(recordings);
    await _transcriptsStore.saveTranscripts(transcripts);

    activeRecordingPath = null;
    recordingSeconds = 0;
    recordingPhase = RecordingPhase.idle;
    notifyListeners();
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
        text:
            '\uC774 \uAD6C\uAC04\uC740 \uC804\uC0AC \uBAA8\uD615\uC758 \uC608\uC2DC \uBB38\uC7A5\uC785\uB2C8\uB2E4. \uC2E4\uC81C STT \uC5D4\uC9C4\uC774 \uC5F0\uACB0\uB418\uBA74 \uC774 \uBB38\uC7A5\uC740 \uD55C\uAD6D\uC5B4 \uB300\uD654 \uB0B4\uC6A9\uC73C\uB85C \uAD50\uCCB4\uB429\uB2C8\uB2E4.',
      ),
      TranscriptSegment(
        id: '${item.id}-s2',
        speaker: 'SPEAKER_01',
        startSeconds: 33,
        endSeconds: min(68, item.durationSeconds),
        text:
            '\uC774\uC81C MVP \uB2E8\uACC4\uC5D0\uC11C\uB294 \uB179\uC74C, \uC804\uC0AC, \uC800\uC7A5, \uC218\uC815 \uD750\uB984\uC744 \uBA3C\uC800 \uC548\uC815\uC801\uC73C\uB85C \uB3CC\uB9AC\uB294 \uAC83\uC774 \uC911\uC694\uD569\uB2C8\uB2E4.',
      ),
      TranscriptSegment(
        id: '${item.id}-s3',
        speaker: 'SPEAKER_02',
        startSeconds: 69,
        endSeconds: item.durationSeconds,
        text:
            '\uAC80\uC0C9, \uACF5\uC720, \uB0B4\uBCF4\uB0B4\uAE30 \uAE30\uB2A5\uC740 \uC804\uC0AC \uAE30\uBCF8\uC744 \uAC16\uCD98 \uB4A4 \uACC4\uC18D \uD655\uC7A5\uD569\uB2C8\uB2E4.',
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

  String _suggestTranscriptTitle(RecordingItem item) {
    final String month = item.createdAt.month.toString().padLeft(2, '0');
    final String day = item.createdAt.day.toString().padLeft(2, '0');
    final String hour = item.createdAt.hour.toString().padLeft(2, '0');
    final String minute = item.createdAt.minute.toString().padLeft(2, '0');
    return '\uB179\uC74C $month/$day $hour:$minute';
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

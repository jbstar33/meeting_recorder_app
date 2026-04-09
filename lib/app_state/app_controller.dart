import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/recording_item.dart';
import '../data/models/transcript_item.dart';
import '../data/models/session_state.dart';
import '../services/recording/audio_recorder_service.dart';
import '../services/export/transcript_export_service.dart';
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
      authError = 'PIN must be exactly 4 digits.';
      notifyListeners();
      return false;
    }
    if (first != second) {
      authError = 'The PIN entries do not match.';
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
      authError = 'Incorrect PIN. Please try again.';
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
      recordingError = 'Microphone permission is required before recording.';
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
      title: 'Meeting ${createdAt.month}/${createdAt.day} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
      filePath: finalPath ?? activeRecordingPath!,
      createdAt: createdAt,
      durationSeconds: recordingSeconds,
      status: 'Saved',
      summary: 'Recording captured on-device. Transcription and analysis are next.',
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
        text: 'Draft transcript for ${item.title}. This placeholder will be replaced by the STT engine.',
      ),
      TranscriptSegment(
        id: '${item.id}-s2',
        speaker: 'SPEAKER_01',
        startSeconds: 33,
        endSeconds: min(68, item.durationSeconds),
        text: 'The current MVP already stores audio locally and keeps the transcript editable.',
      ),
      TranscriptSegment(
        id: '${item.id}-s3',
        speaker: 'SPEAKER_02',
        startSeconds: 69,
        endSeconds: item.durationSeconds,
        text: 'Search, filters, and edits will keep working on top of this transcript draft.',
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
    return 'Transcript $month/$day $hour:$minute';
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

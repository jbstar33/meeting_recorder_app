import 'package:flutter/material.dart';

import 'app.dart';
import 'app_state/app_controller.dart';
import 'services/recording/audio_recorder_service.dart';
import 'services/export/transcript_export_service.dart';
import 'services/security/pin_service.dart';
import 'services/stt/android_local_stt_setup_service.dart';
import 'services/stt/cloud_stt_service.dart';
import 'services/stt/local_stt_service.dart';
import 'services/stt/stt_settings_service.dart';
import 'services/storage/recordings_store.dart';
import 'services/storage/transcripts_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppController controller = AppController(
    pinService: PinService(),
    recordingsStore: RecordingsStore(),
    transcriptsStore: TranscriptsStore(),
    exportService: TranscriptExportService(),
    recorderService: AudioRecorderService(),
    cloudSttService: CloudSttService(
      apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
      baseUrl: const String.fromEnvironment('OPENAI_BASE_URL', defaultValue: 'https://api.openai.com/v1'),
      model: const String.fromEnvironment('OPENAI_STT_MODEL', defaultValue: 'whisper-1'),
    ),
    localSttService: const LocalSttService(),
    androidLocalSttSetupService: const AndroidLocalSttSetupService(),
    sttSettingsService: SttSettingsService(),
  );

  runApp(VoiceNoteApp(controller: controller));
}

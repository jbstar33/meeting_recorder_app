import 'package:flutter/material.dart';

import 'app.dart';
import 'app_state/app_controller.dart';
import 'services/recording/audio_recorder_service.dart';
import 'services/security/pin_service.dart';
import 'services/storage/recordings_store.dart';
import 'services/storage/transcripts_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppController controller = AppController(
    pinService: PinService(),
    recordingsStore: RecordingsStore(),
    transcriptsStore: TranscriptsStore(),
    recorderService: AudioRecorderService(),
  );
  await controller.bootstrap();

  runApp(VoiceNoteApp(controller: controller));
}

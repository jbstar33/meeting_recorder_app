import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meeting_recorder_app/app.dart';
import 'package:meeting_recorder_app/app_state/app_controller.dart';
import 'package:meeting_recorder_app/data/models/session_state.dart';
import 'package:meeting_recorder_app/services/export/transcript_export_service.dart';
import 'package:meeting_recorder_app/services/recording/audio_recorder_service.dart';
import 'package:meeting_recorder_app/services/security/pin_service.dart';
import 'package:meeting_recorder_app/services/stt/android_local_stt_setup_service.dart';
import 'package:meeting_recorder_app/services/stt/cloud_stt_service.dart';
import 'package:meeting_recorder_app/services/stt/local_stt_service.dart';
import 'package:meeting_recorder_app/services/stt/stt_settings_service.dart';
import 'package:meeting_recorder_app/services/storage/recordings_store.dart';
import 'package:meeting_recorder_app/services/storage/transcripts_store.dart';

void main() {
  testWidgets('renders the unlocked app shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppController controller = AppController(
      pinService: PinService(),
      recordingsStore: RecordingsStore(),
      transcriptsStore: TranscriptsStore(),
      exportService: TranscriptExportService(),
      recorderService: AudioRecorderService(),
      cloudSttService: const CloudSttService(apiKey: ''),
      localSttService: const LocalSttService(),
      androidLocalSttSetupService: const AndroidLocalSttSetupService(),
      sttSettingsService: SttSettingsService(),
    );
    controller.authState = AuthState.unlocked;

    await tester.pumpWidget(VoiceNoteApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Meeting Recorder App'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:meeting_recorder_app/app.dart';
import 'package:meeting_recorder_app/app_state/app_controller.dart';
import 'package:meeting_recorder_app/data/models/session_state.dart';
import 'package:meeting_recorder_app/services/recording/audio_recorder_service.dart';
import 'package:meeting_recorder_app/services/security/pin_service.dart';
import 'package:meeting_recorder_app/services/storage/recordings_store.dart';

void main() {
  testWidgets('renders the unlocked app shell', (WidgetTester tester) async {
    final AppController controller = AppController(
      pinService: PinService(),
      recordingsStore: RecordingsStore(),
      recorderService: AudioRecorderService(),
    );
    controller.authState = AuthState.unlocked;

    await tester.pumpWidget(VoiceNoteApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Meeting Recorder App'), findsOneWidget);
  });
}

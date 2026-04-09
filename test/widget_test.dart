import 'package:flutter_test/flutter_test.dart';

import 'package:voicenote_ai/app.dart';
import 'package:voicenote_ai/app_state/app_controller.dart';
import 'package:voicenote_ai/data/models/session_state.dart';
import 'package:voicenote_ai/services/recording/audio_recorder_service.dart';
import 'package:voicenote_ai/services/security/pin_service.dart';
import 'package:voicenote_ai/services/storage/recordings_store.dart';

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

    expect(find.text('VoiceNote AI'), findsOneWidget);
  });
}

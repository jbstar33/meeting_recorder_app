import 'package:flutter/material.dart';

import 'app_state/app_controller.dart';
import 'app_state/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/auth_gate_screen.dart';

class VoiceNoteApp extends StatefulWidget {
  const VoiceNoteApp({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<VoiceNoteApp> createState() => _VoiceNoteAppState();
}

class _VoiceNoteAppState extends State<VoiceNoteApp> {
  String? _startupError;
  bool _bootstrapStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapStarted) {
      return;
    }
    _bootstrapStarted = true;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await widget.controller.bootstrap();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _startupError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: widget.controller,
      child: MaterialApp(
        title: 'Meeting Recorder App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: _startupError == null
            ? const AuthGateScreen()
            : _StartupErrorScreen(
                message: _startupError!,
                onRetry: () {
                  setState(() {
                    _startupError = null;
                    _bootstrapStarted = false;
                  });
                  _bootstrap();
                },
              ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    '\uC571 \uC2DC\uC791\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\uCD08\uAE30\uD654 \uC911 \uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4. \uC544\uB798 \uB0B4\uC6A9\uC744 \uD655\uC778\uD55C \uB4A4 \uB2E4\uC2DC \uC2DC\uB3C4\uD574 \uC8FC\uC138\uC694.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('\uB2E4\uC2DC \uC2DC\uB3C4'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

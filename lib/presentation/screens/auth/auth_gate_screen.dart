import 'package:flutter/material.dart';

import '../../../app_state/app_scope.dart';
import '../../../data/models/session_state.dart';
import '../home/home_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    switch (controller.authState) {
      case AuthState.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthState.needsPinSetup:
        return const PinSetupScreen();
      case AuthState.locked:
        return const PinUnlockScreen();
      case AuthState.unlocked:
        return const HomeScreen();
    }
  }
}

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    '\uC548\uC804\uD55C PIN\uC744 \uB9CC\uB4E4\uC5B4 \uC8FC\uC138\uC694',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\uC571\uC744 \uC5F4\uAE30 \uC804\uC5D0 4\uC790\uB9AC PIN\uC73C\uB85C \uB179\uC74C\uACFC \uC74C\uC131-\uD14D\uC2A4\uD2B8 \uBCC0\uD658\uC744 \uBCF4\uD638\uD569\uB2C8\uB2E4.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: '\uC0C8 PIN',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'PIN \uD655\uC778',
                      counterText: '',
                    ),
                  ),
                  if (controller.authError != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      controller.authError!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      controller.createPin(
                        _pinController.text.trim(),
                        _confirmController.text.trim(),
                      );
                    },
                    child: const Text('PIN \uC800\uC7A5'),
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

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Meeting Recorder App \uC7A0\uAE08 \uD574\uC81C',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '4\uC790\uB9AC PIN\uC744 \uC785\uB825\uD558\uBA74 \uB179\uC74C\uACFC \uC74C\uC131-\uD14D\uC2A4\uD2B8 \uBCC0\uD658\uC744 \uBCFC \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      counterText: '',
                    ),
                    onSubmitted: (_) => controller.unlock(_pinController.text.trim()),
                  ),
                  if (controller.authError != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      controller.authError!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => controller.unlock(_pinController.text.trim()),
                    child: const Text('\uC7A0\uAE08 \uD574\uC81C'),
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

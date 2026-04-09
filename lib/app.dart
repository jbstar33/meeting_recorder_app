import 'package:flutter/material.dart';

import 'app_state/app_controller.dart';
import 'app_state/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/auth_gate_screen.dart';

class VoiceNoteApp extends StatelessWidget {
  const VoiceNoteApp({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: 'VoiceNote AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthGateScreen(),
      ),
    );
  }
}

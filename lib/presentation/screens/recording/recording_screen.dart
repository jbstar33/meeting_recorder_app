import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../app_state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/session_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/speaker_chip.dart';
import '../../widgets/waveform_bar.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('\uB179\uC74C')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          if (kIsWeb) ...<Widget>[
            GlassCard(
              child: Text(
                '\uC6F9 \uBC84\uC804\uC740 UI \uD655\uC778 \uC6A9\uB3C4\uB85C\uB9CC \uC81C\uACF5\uB418\uBA70, \uC2E4\uC81C \uB179\uC74C\uC740 \uC9C0\uC6D0\uD558\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: controller.recordingPhase == RecordingPhase.recording
                            ? AppColors.error
                            : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _phaseLabel(controller.recordingPhase),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(_clock(controller.recordingSeconds), style: theme.textTheme.headlineLarge),
                const SizedBox(height: 18),
                const WaveformBar(),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <Widget>[
                    SpeakerChip(label: '16kHz', index: 0),
                    SpeakerChip(label: 'AAC mono', index: 2),
                    SpeakerChip(label: '\uB85C\uCEEC \uC800\uC7A5', index: 3),
                  ],
                ),
              ],
            ),
          ),
          if (controller.recordingError != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              controller.recordingError!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          if (controller.transcriptionError != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              controller.transcriptionError!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          if (controller.recordingPhase == RecordingPhase.idle)
            _ActionButton(
              icon: Icons.fiber_manual_record_rounded,
              label: '\uB179\uC74C \uC2DC\uC791',
              fillColor: AppColors.primary,
              textColor: Colors.white,
              onPressed: controller.startRecording,
            )
          else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _ActionButton(
                    icon: controller.recordingPhase == RecordingPhase.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    label: controller.recordingPhase == RecordingPhase.paused ? '\uC7AC\uC0DD' : '\uC77C\uC2DC\uC815\uC9C0',
                    fillColor: AppColors.surface,
                    textColor: AppColors.onSurface,
                    onPressed: controller.recordingPhase == RecordingPhase.paused
                        ? controller.resumeRecording
                        : controller.pauseRecording,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.stop_circle_outlined,
                    label: '\uC885\uB8CC',
                    fillColor: AppColors.error,
                    textColor: Colors.white,
                    onPressed: () async {
                      await controller.stopRecording();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  '\uD604\uC7AC MVP \uBC94\uC704',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  controller.recordingPhase == RecordingPhase.idle
                      ? '\uB179\uC74C \uC900\uBE44\uAC00 \uB418\uC5B4 \uC788\uC2B5\uB2C8\uB2E4. \uC624\uB514\uC624 \uD30C\uC77C\uC740 \uB85C\uCEEC\uC5D0 \uC800\uC7A5\uB418\uACE0 \uC885\uB8CC \uD6C4 \uB300\uC2DC\uBCF4\uB4DC\uC5D0 \uCD94\uAC00\uB429\uB2C8\uB2E4.'
                      : '\uB179\uC74C\uAE30\uAC00 \uC9C0\uAE08 \uB85C\uCEEC \uC624\uB514\uC624\uB97C \uC800\uC7A5\uD558\uACE0 \uC788\uC2B5\uB2C8\uB2E4. \uC885\uB8CC\uD558\uBA74 \uC138\uC158\uC774 \uB4A4\uC5D0 \uB179\uC74C \uBAA9\uB85D\uC73C\uB85C \uC800\uC7A5\uB429\uB2C8\uB2E4.',
                ),
                if (controller.activeRecordingPath != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    controller.activeRecordingPath!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (controller.recordingPhase != RecordingPhase.idle) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    '\uB179\uD654 \uC2DC\uAC04: ${formatDuration(controller.recordingSeconds)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _phaseLabel(RecordingPhase phase) {
    switch (phase) {
      case RecordingPhase.idle:
        return '\uC900\uBE44\uC644\uB8CC';
      case RecordingPhase.recording:
        return '\uB179\uC74C \uC911';
      case RecordingPhase.paused:
        return '\uC77C\uC2DC\uC815\uC9C0';
      case RecordingPhase.stopping:
        return '\uC800\uC7A5 \uC911';
    }
  }

  String _clock(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.fillColor,
    required this.textColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color fillColor;
  final Color textColor;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: fillColor,
        foregroundColor: textColor,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      onPressed: onPressed == null ? null : () => onPressed!.call(),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

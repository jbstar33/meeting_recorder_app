import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Recording')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
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
                    SpeakerChip(label: 'Local save', index: 3),
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
          const SizedBox(height: 18),
          if (controller.recordingPhase == RecordingPhase.idle)
            _ActionButton(
              icon: Icons.fiber_manual_record_rounded,
              label: 'Start recording',
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
                    label: controller.recordingPhase == RecordingPhase.paused ? 'Resume' : 'Pause',
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
                    label: 'Stop',
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
                  'Current MVP scope',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  controller.recordingPhase == RecordingPhase.idle
                      ? 'Recording is ready. Audio files are stored locally and added to the dashboard once you stop.'
                      : 'The recorder is writing audio locally right now. After stop, the session is saved to the home list for the next transcript step.',
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
                    'Elapsed: ${formatDuration(controller.recordingSeconds)}',
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
        return 'Ready to record';
      case RecordingPhase.recording:
        return 'Recording live';
      case RecordingPhase.paused:
        return 'Paused';
      case RecordingPhase.stopping:
        return 'Saving';
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

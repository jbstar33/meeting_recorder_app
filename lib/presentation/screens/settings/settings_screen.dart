import 'package:flutter/material.dart';

import '../../../app_state/app_scope.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Text('Security', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const GlassCard(
            child: Column(
              children: <Widget>[
                _SettingRow(title: 'Change PIN', value: '4 digits'),
                Divider(height: 28),
                _SettingRow(title: 'Biometrics', value: 'Planned'),
                Divider(height: 28),
                _SettingRow(title: 'Current session', value: 'Unlocked'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Recording & STT', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: <Widget>[
                const _SettingRow(title: 'Audio quality', value: '16kHz mono'),
                const Divider(height: 28),
                const _SettingRow(title: 'Capture format', value: 'AAC'),
                const Divider(height: 28),
                _SettingRow(title: 'Recorded items', value: '${controller.recordings.length}'),
                const Divider(height: 28),
                const _SettingRow(title: 'STT engine', value: 'Next step'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('AI Analysis', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const GlassCard(
            child: Column(
              children: <Widget>[
                _SettingRow(title: 'Analysis engine', value: 'Planned'),
                Divider(height: 28),
                _SettingRow(title: 'Default template', value: 'Summary'),
                Divider(height: 28),
                _SettingRow(title: 'Export format', value: 'Markdown'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

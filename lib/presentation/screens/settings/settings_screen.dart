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
      appBar: AppBar(title: const Text('\uC124\uC815')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Text('\uBCF4\uC548', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const GlassCard(
            child: Column(
              children: <Widget>[
                _SettingRow(title: 'PIN \uBCC0\uACBD', value: '4\uC790\uB9AC'),
                Divider(height: 28),
                _SettingRow(title: '\uC7A5\uCE58 \uC778\uC99D', value: '\uC124\uC815'),
                Divider(height: 28),
                _SettingRow(title: '\uD604\uC7AC \uC138\uC158', value: '\uC7A0\uAE08 \uD574\uC81C'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('\uB179\uC74C \uBC0F STT', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: <Widget>[
                const _SettingRow(title: '\uC624\uB514\uC624 \uC0AC\uC6A9\uD654', value: '16kHz mono'),
                const Divider(height: 28),
                const _SettingRow(title: '\uC800\uC7A5 \uD615\uC2DD', value: 'AAC'),
                const Divider(height: 28),
                _SettingRow(title: '\uC800\uC7A5\uB41C \uD56D\uBAA9', value: '${controller.recordings.length}'),
                const Divider(height: 28),
                const _SettingRow(title: 'STT \uC5B8\uC5B4', value: '\uD55C\uAD6D\uC5B4'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('AI \uBD84\uC11D', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const GlassCard(
            child: Column(
              children: <Widget>[
                _SettingRow(title: '\uBD84\uC11D \uC5D4\uC9C4', value: '\uC124\uC815'),
                Divider(height: 28),
                _SettingRow(title: '\uAE30\uBCF8 \uD15C\uD50C\uB9BF', value: '\uC608\uC57D'),
                Divider(height: 28),
                _SettingRow(title: '\uB0B4\uBCF4\uB0B4\uAE30 \uD615\uC2DD', value: 'Markdown'),
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

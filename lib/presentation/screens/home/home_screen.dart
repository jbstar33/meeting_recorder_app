import 'package:flutter/material.dart';

import '../../../app_state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/recording_item.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/speaker_chip.dart';
import '../../widgets/waveform_bar.dart';
import '../recording/recording_screen.dart';
import '../settings/settings_screen.dart';
import '../transcript/transcript_list_screen.dart';
import '../transcript/transcript_search_screen.dart';
import '../transcript/transcript_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const _DashboardTab(),
      const TranscriptListScreen(),
      const TranscriptSearchScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const RecordingScreen(),
            ),
          );
        },
        child: const Icon(Icons.mic_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '\uD648',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: '\uB179\uC74C',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: '\uAC80\uC0C9',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: '\uC124\uC815',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final ThemeData theme = Theme.of(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          pinned: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          expandedHeight: 172,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 24, bottom: 20),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Meeting Recorder App',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  '\uC0AC\uC9C4\uACFC \uC815\uBCF4\uAC00 \uC544\uB2CC \uC804\uCCB4 \uB179\uC74C \uD750\uB984\uC744 \uC218\uC815\uD558\uB294 \uC571\uC785\uB2C8\uB2E4.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFD9EEFB),
                    Color(0xFFF4F9FE),
                  ],
                ),
              ),
              child: const Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    top: -10,
                    right: -20,
                    child: _Bubble(size: 160, color: Color(0x665B9BD5)),
                  ),
                  Positioned(
                    bottom: 8,
                    left: -30,
                    child: _Bubble(size: 120, color: Color(0x33A8D1F0)),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                _HeroSummary(recordingsCount: controller.recordings.length),
                const SizedBox(height: 18),
                _SectionHeader(title: '\uCD5C\uADFC \uB179\uC74C', action: '\uC571 \uC7A0\uAE08', onTap: controller.lock),
                const SizedBox(height: 12),
                if (controller.recordings.isEmpty)
                  const GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '\uC544\uC9C1 \uB179\uC74C\uC774 \uC5C6\uC2B5\uB2C8\uB2E4',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '\uB9C8\uC774\uD06C \uBC84\uD2BC\uC744 \uB20C\uB7EC \uCCAB \uB179\uC74C\uC744 \uC0DD\uC131\uD558\uC138\uC694. \uB85C\uCEEC \uAE30\uAE30\uC5D0 \uC800\uC7A5\uB429\uB2C8\uB2E4.',
                        ),
                      ],
                    ),
                  ),
                ...controller.recordings.asMap().entries.map((MapEntry<int, RecordingItem> entry) {
                  final int index = entry.key;
                  final RecordingItem item = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        controller.selectRecording(item);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TranscriptDetailScreen(),
                          ),
                        );
                      },
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(item.title, style: theme.textTheme.titleLarge),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${formatDateTime(item.createdAt)}  ·  ${formatDuration(item.durationSeconds)}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              item.summary ?? '\uB85C\uCEEC\uC5D0 \uC800\uC7A5\uB418\uC5C8\uC2B5\uB2C8\uB2E4. \uB4A4\uC774\uC5B4 \uAC80\uC0C9\uACFC \uBD84\uC11D \uAE30\uB2A5\uC744 \uCD94\uAC00\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                SpeakerChip(label: '\uB85C\uCEEC \uD30C\uC77C 1\uAC1C', index: index),
                                const SizedBox(width: 8),
                                const SpeakerChip(label: '\uC624\uD504\uB77C\uC778 \uC6B0\uC120', index: 0),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.recordingsCount});

  final int recordingsCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$recordingsCount\uAC1C \uB85C\uCEEC \uB179\uC74C',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\uC18C\uC911\uD55C \uB0B4\uC6A9\uC744 \uC548\uC804\uD558\uAC8C \uB179\uC74C\uD558\uACE0,\n\uD655\uC2E4\uD558\uAC8C \uB2E4\uC2DC \uB4E4\uC744 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\uC774 MVP\uB294 \uC9C0\uAE08 \uC2E4\uC81C PIN \uC7A0\uAE08\uACFC \uB85C\uCEEC \uC624\uB514\uC624 \uB179\uC74C\uC744 \uD3EC\uD568\uD569\uB2C8\uB2E4.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 20),
          const WaveformBar(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

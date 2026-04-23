import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app_state/app_scope.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _pythonController = TextEditingController();
  final TextEditingController _localModelController = TextEditingController();
  final TextEditingController _hfTokenController = TextEditingController();
  final TextEditingController _androidWhisperBinController = TextEditingController();
  final TextEditingController _androidWhisperModelController = TextEditingController();
  bool _didSeed = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    final controller = AppScope.of(context);
    if (controller.sttApiKeyPreview != null) {
      _apiKeyController.text = controller.sttApiKeyPreview!;
    }
    _pythonController.text = controller.localPythonCommand;
    _localModelController.text = controller.localModel;
    _androidWhisperBinController.text = controller.androidWhisperBinPath;
    _androidWhisperModelController.text = controller.androidWhisperModelPath;
    if (controller.localHfTokenPreview != null) {
      _hfTokenController.text = controller.localHfTokenPreview!;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _pythonController.dispose();
    _localModelController.dispose();
    _hfTokenController.dispose();
    _androidWhisperBinController.dispose();
    _androidWhisperModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final ThemeData theme = Theme.of(context);
    final bool isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Text('보안', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const GlassCard(
            child: Column(
              children: <Widget>[
                _SettingRow(title: 'PIN 변경', value: '4자리'),
                Divider(height: 28),
                _SettingRow(title: '장치 인증', value: '설정'),
                Divider(height: 28),
                _SettingRow(title: '현재 세션', value: '잠금 해제'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('변환 엔진', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'local',
                      label: const Text('내장'),
                      enabled: controller.isLocalSttAvailable,
                    ),
                    const ButtonSegment<String>(value: 'cloud', label: Text('클라우드')),
                  ],
                  selected: <String>{controller.sttEngine},
                  onSelectionChanged: (Set<String> value) async {
                    await controller.saveSttEngine(value.first);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  controller.isLocalSttAvailable
                      ? (controller.sttEngine == 'local'
                          ? '내장 모델 사용 (데스크톱: faster-whisper, Android: whisper.cpp)'
                          : 'OpenAI Cloud STT 사용')
                      : '이 기기에서는 로컬 STT를 지원하지 않습니다. 클라우드 STT를 사용하세요.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('로컬 STT / 화자 분리', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!isAndroid) TextField(
                  controller: _pythonController,
                  decoration: const InputDecoration(
                    labelText: 'Python 명령어',
                    hintText: 'python',
                  ),
                ),
                const SizedBox(height: 10),
                if (!isAndroid) TextField(
                  controller: _localModelController,
                  decoration: const InputDecoration(
                    labelText: 'Whisper 모델',
                    hintText: 'small',
                  ),
                ),
                const SizedBox(height: 10),
                if (!isAndroid) TextField(
                  controller: _hfTokenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Hugging Face Token (선택)',
                    hintText: 'hf_...',
                  ),
                ),
                const SizedBox(height: 12),
                if (!isAndroid) TextField(
                  controller: _androidWhisperBinController,
                  decoration: const InputDecoration(
                    labelText: 'Android whisper-cli 경로',
                    hintText: '/data/user/0/.../files/whisper-cli',
                  ),
                ),
                const SizedBox(height: 10),
                if (!isAndroid) TextField(
                  controller: _androidWhisperModelController,
                  decoration: const InputDecoration(
                    labelText: 'Android 모델 경로',
                    hintText: '/data/user/0/.../files/models/ggml-base.bin',
                  ),
                ),
                const SizedBox(height: 10),
                if (isAndroid)
                  Text(
                    'Android는 APK에 내장된 엔진/모델을 설치합니다. 아래 버튼만 누르면 됩니다.',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                if (!isAndroid) FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                          setState(() => _isSaving = true);
                          await controller.saveLocalSttConfig(
                            pythonCommand: _pythonController.text,
                            model: _localModelController.text,
                            hfToken: _hfTokenController.text,
                            androidBinPath: _androidWhisperBinController.text,
                            androidModelPath: _androidWhisperModelController.text,
                            androidBinUrl: '',
                            androidModelUrl: '',
                          );
                          if (!mounted) {
                            return;
                          }
                          setState(() => _isSaving = false);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('로컬 STT 설정이 저장되었습니다.')),
                          );
                        },
                  icon: const Icon(Icons.memory_rounded),
                  label: const Text('로컬 설정 저장'),
                ),
                const SizedBox(height: 10),
                if (isAndroid)
                  FilledButton.tonalIcon(
                    onPressed: controller.isInstallingLocalStt
                        ? null
                        : () async {
                            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                            await controller.saveLocalSttConfig(
                              pythonCommand: _pythonController.text,
                              model: _localModelController.text,
                              hfToken: _hfTokenController.text,
                              androidBinPath: _androidWhisperBinController.text,
                              androidModelPath: _androidWhisperModelController.text,
                              androidBinUrl: '',
                              androidModelUrl: '',
                            );
                            final bool ok = await controller.installAndroidLocalSttFromUrls();
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Android 내장 로컬 STT 설치 완료'
                                      : (controller.transcriptionError ?? 'Android 로컬 STT 설치 실패'),
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.memory_rounded),
                    label: Text(
                      controller.isInstallingLocalStt
                          ? '설치 중...'
                          : '내장 엔진 설치 (Android)',
                    ),
                  ),
                if (controller.isInstallingLocalStt) ...<Widget>[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: controller.localSttInstallProgress <= 0
                        ? null
                        : controller.localSttInstallProgress / 100.0,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.localSttInstallProgress}%  ${controller.localSttInstallMessage}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Cloud STT', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'OpenAI API Key',
                    hintText: 'sk-...',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  controller.hasCloudSttApiKey
                      ? 'API Key 저장됨 (${controller.sttApiKeyPreview ?? '****'})'
                      : 'API Key가 없어 클라우드 STT가 비활성 상태입니다.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                              setState(() => _isSaving = true);
                              await controller.saveSttApiKey(_apiKeyController.text);
                              if (!mounted) {
                                return;
                              }
                              setState(() => _isSaving = false);
                              messenger.showSnackBar(
                                const SnackBar(content: Text('API Key가 저장되었습니다.')),
                              );
                            },
                      icon: const Icon(Icons.key),
                      label: const Text('저장'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              _apiKeyController.clear();
                              await controller.clearSttApiKey();
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('키 제거'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('웹 마이크 권한', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  controller.microphonePermissionGranted ? '마이크 권한 허용' : '마이크 권한 미허용',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: controller.requestMicrophonePermission,
                      icon: const Icon(Icons.mic),
                      label: const Text('권한 요청'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.refreshMicrophonePermission,
                      icon: const Icon(Icons.refresh),
                      label: const Text('상태 확인'),
                    ),
                  ],
                ),
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

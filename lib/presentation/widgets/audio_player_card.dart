import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import 'glass_card.dart';

class AudioPlayerCard extends StatefulWidget {
  const AudioPlayerCard({
    super.key,
    required this.filePath,
  });

  final String? filePath;

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = true;
  bool _sourceReady = false;
  bool _isPlaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _preparePlayer();
  }

  @override
  void didUpdateWidget(covariant AudioPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _disposeSubscriptions();
      _preparePlayer();
    }
  }

  Future<void> _preparePlayer() async {
    final String? filePath = widget.filePath;
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _sourceReady = false;
      _isPlaying = false;
      _error = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    if (filePath == null || filePath.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '재생할 녹음 파일이 없습니다.';
      });
      return;
    }

    if (!_isWebPlayableUrl(filePath)) {
      final File file = File(filePath);
      if (!file.existsSync()) {
        setState(() {
          _isLoading = false;
          _error = '로컬 녹음 파일을 찾을 수 없습니다.';
        });
        return;
      }
      if (file.lengthSync() <= 44) {
        setState(() {
          _isLoading = false;
          _error = '녹음 파일이 너무 작아 재생할 수 없습니다.';
        });
        return;
      }
    }

    _positionSubscription = _player.onPositionChanged.listen((Duration position) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = position;
      });
    });

    _durationSubscription = _player.onDurationChanged.listen((Duration duration) {
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = duration;
      });
    });

    _stateSubscription = _player.onPlayerStateChanged.listen((PlayerState state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _player.onPlayerComplete.listen((_) async {
      await _player.seek(Duration.zero);
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _ensureSourceLoaded() async {
    if (_sourceReady) {
      return;
    }

    final String? filePath = widget.filePath;
    if (filePath == null || filePath.isEmpty) {
      throw StateError('재생할 녹음 파일이 없습니다.');
    }

    if (_isWebPlayableUrl(filePath)) {
      await _player.setSourceUrl(filePath).timeout(const Duration(seconds: 5));
      _sourceReady = true;
      return;
    }

    await _player.setSourceDeviceFile(filePath).timeout(const Duration(seconds: 5));
    _sourceReady = true;
  }

  void _disposeSubscriptions() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    _positionSubscription = null;
    _durationSubscription = null;
    _stateSubscription = null;
  }

  @override
  void dispose() {
    _disposeSubscriptions();
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.play_circle_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                '녹음 듣기',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Text(_error!)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Slider(
                  value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                  max: (_duration.inMilliseconds <= 0 ? 1 : _duration.inMilliseconds).toDouble(),
                  onChanged: _duration.inMilliseconds <= 0
                      ? null
                      : (double value) {
                          _player.seek(Duration(milliseconds: value.toInt()));
                        },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(formatDuration(_position.inSeconds)),
                    Text(formatDuration(_duration.inSeconds)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          await _ensureSourceLoaded();
                          if (_isPlaying) {
                            await _player.pause();
                          } else {
                            await _player.resume().timeout(const Duration(seconds: 5));
                          }
                          if (mounted) {
                            setState(() {
                              _error = null;
                            });
                          }
                        } on TimeoutException {
                          if (mounted) {
                            setState(() {
                              _error = '재생 준비 시간이 초과되었습니다. 파일을 다시 녹음해 주세요.';
                            });
                          }
                        } catch (error) {
                          if (mounted) {
                            setState(() {
                              _error = '재생에 실패했습니다: $error';
                            });
                          }
                        }
                      },
                      icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_isPlaying ? '일시정지' : '재생'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _player.stop();
                        if (mounted) {
                          setState(() {
                            _position = Duration.zero;
                            _isPlaying = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('정지'),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  bool _isWebPlayableUrl(String path) {
    if (!kIsWeb) {
      return false;
    }
    return path.startsWith('data:') || path.startsWith('blob:') || path.startsWith('http');
  }
}

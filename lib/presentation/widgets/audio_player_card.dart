import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = true;
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
    if (filePath == null || filePath.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '\uC7AC\uC0DD\uD560 \uB179\uC74C \uD30C\uC77C\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.';
      });
      return;
    }

    final File file = File(filePath);
    if (!file.existsSync()) {
      setState(() {
        _isLoading = false;
        _error = '\uB85C\uCEEC \uB179\uC74C \uD30C\uC77C\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.';
      });
      return;
    }

    try {
      _position = Duration.zero;
      _duration = Duration.zero;
      await _player.setFilePath(filePath);
      _duration = _player.duration ?? Duration.zero;
      _positionSubscription = _player.positionStream.listen((Duration position) {
        if (!mounted) {
          return;
        }
        setState(() {
          _position = position;
        });
      });
      _playerStateSubscription = _player.playerStateStream.listen((PlayerState state) {
        if (!mounted) {
          return;
        }
        if (state.processingState == ProcessingState.completed) {
          unawaited(_player.seek(Duration.zero));
          unawaited(_player.pause());
        }
        setState(() {});
      });
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _disposeSubscriptions() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_playerStateSubscription?.cancel());
    _positionSubscription = null;
    _playerStateSubscription = null;
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
                '\uB179\uC74C \uB4E3\uAE30',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
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
                        if (_player.playing) {
                          await _player.pause();
                        } else {
                          await _player.play();
                        }
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      icon: Icon(_player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_player.playing ? '\uC77C\uC2DC\uC815\uC9C0' : '\uC7AC\uC0DD'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _player.stop();
                        await _player.seek(Duration.zero);
                        if (mounted) {
                          setState(() {
                            _position = Duration.zero;
                          });
                        }
                      },
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('\uC815\uC9C0'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.filePath ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/content.dart';
import '../services/favorites_provider.dart';
import '../services/locale_provider.dart';

const _sampleVideos = [
  'assets/videos/sample.mp4',
  'assets/videos/video4.mp4',
  'assets/videos/video5.mp4',
  'assets/videos/video6.mp4',
  'assets/videos/sample.mp4',
  'assets/videos/video4.mp4',
  'assets/videos/video5.mp4',
  'assets/videos/video6.mp4',
  'assets/videos/sample.mp4',
  'assets/videos/video4.mp4',
];

bool _isTvActivateEvent(KeyEvent event) {
  final key = event.logicalKey;
  final isActivate =
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.gameButtonA ||
      key == LogicalKeyboardKey.mediaPlayPause;
  if (!isActivate) return false;
  if (key == LogicalKeyboardKey.select) {
    return event is KeyDownEvent || event is KeyUpEvent;
  }
  return event is KeyDownEvent;
}

bool _isTvBackEvent(KeyEvent event) {
  final key = event.logicalKey;
  return key == LogicalKeyboardKey.escape ||
      key == LogicalKeyboardKey.goBack ||
      key == LogicalKeyboardKey.browserBack;
}

class PlayerScreen extends StatefulWidget {
  final Content content;
  const PlayerScreen({super.key, required this.content});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  String? _youtubeId;

  late AnimationController _controlsFade;
  late Animation<double> _controlsOpacity;

  bool _isInitialized = false;
  bool _showControls = true;
  bool _hasError = false;
  Timer? _hideControlsTimer;
  DateTime? _lastProgressSyncAt;
  int _lastBackPopMs = 0;

  bool get _isYoutube => _youtubeId != null;

  @override
  void initState() {
    super.initState();
    _controlsFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _controlsOpacity = CurvedAnimation(
      parent: _controlsFade,
      curve: Curves.easeOut,
    );

    _youtubeId = YoutubePlayer.convertUrlToId(widget.content.youtubeUrl ?? '');
    if (_isYoutube) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: _youtubeId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          disableDragSeek: false,
        ),
      )..addListener(_onYoutubeUpdate);
      _isInitialized = true;
      _scheduleHideControls();
      return;
    }

    final videoUrl =
        _sampleVideos[widget.content.id.hashCode.abs() % _sampleVideos.length];
    _videoController = VideoPlayerController.asset(videoUrl)
      ..addListener(_onVideoUpdate)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() => _isInitialized = true);
            _videoController?.play();
            _scheduleHideControls();
          })
          .catchError((_) {
            if (mounted) setState(() => _hasError = true);
          });
  }

  void _onVideoUpdate() {
    if (!mounted || _videoController == null) return;
    setState(() {});

    final pos = _videoController!.value.position.inSeconds;
    if (!_isInitialized || pos % 3 != 0) return;

    final dur = _videoController!.value.duration.inSeconds;
    if (dur > 0) {
      final p = (pos / dur).clamp(0.0, 0.99);
      context.read<FavoritesProvider>().setProgress(widget.content.id, p);
    }
  }

  void _onYoutubeUpdate() {
    if (!mounted || _youtubeController == null || !_isInitialized) return;
    setState(() {});

    final now = DateTime.now();
    if (_lastProgressSyncAt != null &&
        now.difference(_lastProgressSyncAt!).inSeconds < 3) {
      return;
    }

    final dur = _youtubeController!.metadata.duration.inSeconds;
    final pos = _youtubeController!.value.position.inSeconds;
    if (dur > 0 && pos >= 0) {
      _lastProgressSyncAt = now;
      final p = (pos / dur).clamp(0.0, 0.99);
      context.read<FavoritesProvider>().setProgress(widget.content.id, p);
    }
  }

  bool get _isPlaying {
    if (!_isInitialized) return false;
    if (_isYoutube) return _youtubeController?.value.isPlaying ?? false;
    return _videoController?.value.isPlaying ?? false;
  }

  Duration get _currentPosition {
    if (!_isInitialized) return Duration.zero;
    if (_isYoutube) return _youtubeController?.value.position ?? Duration.zero;
    return _videoController?.value.position ?? Duration.zero;
  }

  Duration get _totalDuration {
    if (!_isInitialized) return Duration.zero;
    if (_isYoutube) {
      return _youtubeController?.metadata.duration ?? Duration.zero;
    }
    return _videoController?.value.duration ?? Duration.zero;
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        _controlsFade.reverse();
        setState(() => _showControls = false);
      }
    });
  }

  void _showAndScheduleHide() {
    if (!_isInitialized) return;
    _controlsFade.forward();
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  void _togglePlay() {
    if (!_isInitialized) return;
    if (_isYoutube) {
      final ctrl = _youtubeController;
      if (ctrl == null) return;
      if (ctrl.value.isPlaying) {
        ctrl.pause();
      } else {
        ctrl.play();
        _scheduleHideControls();
      }
    } else {
      final ctrl = _videoController;
      if (ctrl == null) return;
      if (ctrl.value.isPlaying) {
        ctrl.pause();
      } else {
        ctrl.play();
        _scheduleHideControls();
      }
    }
    _controlsFade.forward();
    setState(() => _showControls = true);
  }

  void _seekRelative(Duration delta) {
    if (!_isInitialized) return;
    final current = _currentPosition;
    final total = _totalDuration;
    final maxMs = total.inMilliseconds > 0 ? total.inMilliseconds : 0;
    final ms = (current + delta).inMilliseconds.clamp(0, maxMs);

    if (_isYoutube) {
      _youtubeController?.seekTo(Duration(milliseconds: ms));
    } else {
      _videoController?.seekTo(Duration(milliseconds: ms));
    }
    _showAndScheduleHide();
  }

  double get _progress {
    if (!_isInitialized) return 0;
    final dur = _totalDuration.inMilliseconds;
    if (dur == 0) return 0;
    return (_currentPosition.inMilliseconds / dur).clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    if (_isInitialized) {
      final pos = _currentPosition.inSeconds;
      final dur = _totalDuration.inSeconds;
      if (dur > 0 && context.mounted) {
        final p = (pos / dur).clamp(0.0, 0.99);
        context.read<FavoritesProvider>().setProgress(widget.content.id, p);
      }
    }

    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _youtubeController?.removeListener(_onYoutubeUpdate);
    _youtubeController?.dispose();
    _hideControlsTimer?.cancel();
    _controlsFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if ((event is KeyDownEvent || event is KeyUpEvent) &&
            _isTvBackEvent(event)) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastBackPopMs < 250) {
            return KeyEventResult.handled;
          }
          _lastBackPopMs = now;
          Navigator.maybePop(context);
          return KeyEventResult.handled;
        }

        if (_isTvActivateEvent(event)) {
          _togglePlay();
          return KeyEventResult.handled;
        }

        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.mediaFastForward)) {
          _seekRelative(const Duration(seconds: 10));
          return KeyEventResult.handled;
        }

        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.mediaRewind)) {
          _seekRelative(const Duration(seconds: -10));
          return KeyEventResult.handled;
        }

        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown)) {
          _showAndScheduleHide();
          return KeyEventResult.handled;
        }

        _showAndScheduleHide();
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          if (_showControls) {
            _controlsFade.reverse();
            setState(() => _showControls = false);
          } else {
            _showAndScheduleHide();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildVideo(),
              FadeTransition(
                opacity: _controlsOpacity,
                child: _buildControls(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (_hasError) {
      final l = Provider.of<LocaleProvider>(context, listen: false);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              l.t('player_error'),
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }

    if (_isYoutube && _youtubeController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: false,
            progressIndicatorColor: const Color(0xFF6C63FF),
          ),
        ),
      );
    }

    final localController = _videoController;
    if (localController == null) return const SizedBox.shrink();

    return Center(
      child: AspectRatio(
        aspectRatio: localController.value.aspectRatio,
        child: VideoPlayer(localController),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final c = widget.content;
    final isPlaying = _isPlaying;
    final position = _currentPosition;
    final duration = _totalDuration;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.88),
          ],
          stops: const [0, 0.25, 0.6, 1],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: Row(
              children: [
                _NavBtn(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        c.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white38),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isYoutube ? 'YOUTUBE' : '4K HDR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: Column(
              children: [
                SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 4,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: Color(0xFF6C63FF),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: (v) {
                      if (!_isInitialized) return;
                      final target = Duration(
                        milliseconds: (v * duration.inMilliseconds).round(),
                      );
                      if (_isYoutube) {
                        _youtubeController?.seekTo(target);
                      } else {
                        _videoController?.seekTo(target);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _fmt(position),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    _ControlBtn(
                      icon: Icons.replay_10,
                      onTap: () => _seekRelative(const Duration(seconds: -10)),
                    ),
                    const SizedBox(width: 16),
                    Focus(
                      autofocus: true,
                      onKeyEvent: (node, event) {
                        if (_isTvActivateEvent(event)) {
                          _togglePlay();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Builder(
                        builder: (ctx) {
                          final focused = Focus.of(ctx).hasFocus;
                          return GestureDetector(
                            onTap: _togglePlay,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: focused
                                    ? Colors.white
                                    : const Color(0xFF6C63FF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: focused
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : const Color(
                                            0xFF6C63FF,
                                          ).withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: focused ? Colors.black : Colors.white,
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    _ControlBtn(
                      icon: Icons.forward_10,
                      onTap: () => _seekRelative(const Duration(seconds: 10)),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(duration),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
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

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: focused
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: focused
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.transparent,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          );
        },
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: focused
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: focused
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.transparent,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          );
        },
      ),
    );
  }
}

import pathlib

code = r"""import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/content.dart';

const _sampleVideos = [
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
];

class PlayerScreen extends StatefulWidget {
  final Content content;
  const PlayerScreen({super.key, required this.content});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _controlsFade;
  late Animation<double> _controlsOpacity;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controlsFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _controlsOpacity =
        CurvedAnimation(parent: _controlsFade, curve: Curves.easeOut);
    final videoUrl = _sampleVideos[widget.content.id % _sampleVideos.length];
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          ..addListener(_onVideoUpdate)
          ..initialize().then((_) {
            if (mounted) {
              setState(() => _isInitialized = true);
              _videoController.play();
              _scheduleHideControls();
            }
          }).catchError((_) {
            if (mounted) setState(() => _hasError = true);
          });
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  void _scheduleHideControls() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _videoController.value.isPlaying) {
        _controlsFade.reverse();
        setState(() => _showControls = false);
      }
    });
  }

  void _showAndScheduleHide() {
    _controlsFade.forward();
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  void _togglePlay() {
    if (!_isInitialized) return;
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
      _scheduleHideControls();
    }
    _controlsFade.forward();
    setState(() => _showControls = true);
  }

  void _seekRelative(Duration delta) {
    if (!_isInitialized) return;
    final current = _videoController.value.position;
    final total = _videoController.value.duration;
    final newPos = (current + delta).clamp(Duration.zero, total);
    _videoController.seekTo(newPos);
    _showAndScheduleHide();
  }

  double get _progress {
    if (!_isInitialized) return 0;
    final dur = _videoController.value.duration.inMilliseconds;
    if (dur == 0) return 0;
    return (_videoController.value.position.inMilliseconds / dur)
        .clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _videoController
      ..removeListener(_onVideoUpdate)
      ..dispose();
    _controlsFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        // Orqaga - har doim ishlaydi
        if (event.logicalKey == LogicalKeyboardKey.goBack ||
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          _togglePlay();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _seekRelative(const Duration(seconds: 10));
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _seekRelative(const Duration(seconds: -10));
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: Colors.white54, size: 64),
            SizedBox(height: 16),
            Text(
              'Video yuklanmadi',
              style: TextStyle(color: Colors.white54, fontSize: 18),
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
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: VideoPlayer(_videoController),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final c = widget.content;
    final isPlaying = _isInitialized && _videoController.value.isPlaying;
    final position =
        _isInitialized ? _videoController.value.position : Duration.zero;
    final duration =
        _isInitialized ? _videoController.value.duration : Duration.zero;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.75),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.88),
          ],
          stops: const [0, 0.25, 0.6, 1],
        ),
      ),
      child: Column(
        children: [
          // ── TOP BAR ──
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
                          color: Colors.white.withOpacity(0.6),
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
                  child: const Text(
                    '4K HDR',
                    style: TextStyle(
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
          // ── BOTTOM CONTROLS ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: const Color(0xFF6C63FF),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: (v) {
                      if (_isInitialized) {
                        _videoController.seekTo(Duration(
                          milliseconds: (v * duration.inMilliseconds).round(),
                        ));
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
                        color: Colors.white.withOpacity(0.8),
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
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.select ||
                                event.logicalKey == LogicalKeyboardKey.enter)) {
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
                                        ? Colors.white.withOpacity(0.4)
                                        : const Color(0xFF6C63FF)
                                            .withOpacity(0.5),
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
                        color: Colors.white.withOpacity(0.5),
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

// ── Orqaga tugmasi (D-pad Enter ni qo'llab-quvvatlaydi) ──
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
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
                    ? Colors.white.withOpacity(0.25)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: focused
                      ? Colors.white.withOpacity(0.7)
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

// ── Replay / Forward tugmasi ──
class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
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
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: focused
                      ? Colors.white.withOpacity(0.6)
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
"""

pathlib.Path(r'C:\Users\laptop\StudioProjects\Smart tv app\lib\screens\player_screen.dart').write_text(code, encoding='utf-8')
print('Done -', len(code.splitlines()), 'lines')

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/wp_reels_api.dart';
import '../../models/wp_reel.dart';
import '../../theme/brand.dart'; // keep using your Brand file
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReelsScreen extends StatefulWidget {
  final int initialIndex;
  final int? initialReelId; // ⬅ NEW

  const ReelsScreen({
    super.key,
    this.initialIndex = 0,
    this.initialReelId,
  });

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _page = PageController();
  final Map<int, VideoPlayerController> _controllers = {};
  final _rng = Random();
  final List<WPReel> _items = [];

  int _current = 0;
  bool _loading = true;
  bool _error = false;

  bool _showControls = false;
  bool _showPauseOverlay = false;
  Timer? _hideTimer;
  Timer? _pauseOverlayTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pauseOverlayTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _page.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final fresh = await WpReelsApi.fetchRecent(perPage: 10);
      if (!mounted) return;
      fresh.shuffle(_rng);
      _items..clear()..addAll(fresh);
      setState(() => _loading = false);

// ensure controllers
      await _ensureController(_current);
      await _ensureController(_current + 1);

// If a specific reel id was requested, jump to it
      if (widget.initialReelId != null) {
        final idx = _items.indexWhere((r) => r.id == widget.initialReelId);
        if (idx >= 0) {
          _current = idx;
          _page.jumpToPage(idx);
          await _ensureController(idx);
          _playOnly(idx);
        } else {
          _playOnly(_current);
        }
      } else {
        _playOnly(_current);
      }

      if (_items.isNotEmpty) {
        unawaited(WpReelsApi.incrementView(_items[_current].id));
      }

    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _playOnly(int index) {
    _controllers.forEach((i, c) {
      if (!c.value.isInitialized) return;
      if (i == index) {
        c.seekTo(Duration.zero); // always from start
        c.setVolume(1.0);        // play with sound by default
        c.play();
      } else {
        c.pause();
      }
    });
    // ensure overlay off after page change
    setState(() => _showPauseOverlay = false);
  }

  Future<void> _ensureController(int index) async {
    if (index < 0 || index >= _items.length) return;
    if (_controllers.containsKey(index)) return;

    final reel = _items[index];
    final url = reel.videoUrl.isNotEmpty ? reel.videoUrl : reel.hlsUrl;
    if (url.isEmpty) return;

    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = c;

    try {
      await c.initialize();
      c.setLooping(true);
      c.setVolume(1.0);

      // ✅ Auto-play immediately if this is the current visible video
      if (index == _current) {
        c.seekTo(Duration.zero);
        c.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    _playOnly(i);
    _ensureController(i + 1);

    if (i >= 0 && i < _items.length) {
      WpReelsApi.incrementView(_items[i].id);
    }
    // infinite/random: append a shuffled copy when near end
    if (i >= _items.length - 2) {
      final extra = List<WPReel>.from(_items)..shuffle(_rng);
      setState(() => _items.addAll(extra));
    }
    // hide controls on page switch
    _toggleControls(force: false);
  }

  void _toggleControls({bool? force}) {
    final next = force ?? !_showControls;
    setState(() => _showControls = next);
    _hideTimer?.cancel();
    if (next) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  void _showPauseIconTemporarily() {
    setState(() => _showPauseOverlay = true);
    _pauseOverlayTimer?.cancel();
    _pauseOverlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showPauseOverlay = false);
    });
  }

  /// Single source of truth to play/pause the **current** video,
  /// update UI, show overlay, and keep controls in sync.
  void _playPauseCurrent() {
    final c = _controllers[_current];
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});           // refresh icons everywhere
    _showPauseIconTemporarily();
    _toggleControls(force: true); // reveal controls briefly
  }

  void _toggleMuteCurrent() {
    final c = _controllers[_current];
    if (c == null || !c.value.isInitialized) return;
    c.setVolume(c.value.volume == 0 ? 1.0 : 0.0);
    setState(() {}); // refresh mute icon
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return Center(
        child: FilledButton(
          onPressed: _fetch,
          child: const Text('Retry'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final reel = _items[i];
              final c = _controllers[i];
              return _ReelPage(
                reel: reel,
                controller: c,
                isCurrent: i == _current,
                showControls: _showControls,
                showPauseOverlay: _showPauseOverlay,
                onTapAnywherePlayPause: _playPauseCurrent,
                onCenterOverlayTap: _playPauseCurrent,
                onToggleMute: _toggleMuteCurrent,
                onShare: () => Share.share(reel.link ?? reel.videoUrl ?? ''),
                onLike: () => WpReelsApi.like(reel.id),
                requestRebuild: () => setState(() {}),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "News",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  final WPReel reel;
  final VideoPlayerController? controller;
  final bool isCurrent;
  final bool showControls;
  final bool showPauseOverlay;

  final VoidCallback onTapAnywherePlayPause;
  final VoidCallback onCenterOverlayTap;
  final VoidCallback onToggleMute;
  final VoidCallback onShare;
  final Future<void> Function() onLike;
  final VoidCallback requestRebuild;

  const _ReelPage({
    required this.reel,
    required this.controller,
    required this.isCurrent,
    required this.showControls,
    required this.showPauseOverlay,
    required this.onTapAnywherePlayPause,
    required this.onCenterOverlayTap,
    required this.onToggleMute,
    required this.onShare,
    required this.onLike,
    required this.requestRebuild,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = controller != null && controller!.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        /// ▶ Video Player + overlay tint
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTapAnywherePlayPause,
          onDoubleTap: onLike,
          child: hasVideo
              ? Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.size.width,
                  height: controller!.value.size.height,
                  child: VideoPlayer(controller!),
                ),
              ),
              // Slight dark overlay for readability
              Container(color: Colors.black.withOpacity(0.25)),
            ],
          )
              : Container(color: Colors.black),
        ),

        /// 📝 Title block
        Positioned(
          left: 14,
          right: 88,
          bottom: 20,
          child: SafeArea(
            child: Text(
              reel.titleRendered ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                height: 1.2,
              ),
            ),
          ),
        ),

        /// 💬 Right-side interactive buttons (Download, WhatsApp, Share only)
        Positioned(
          right: 14,
          bottom: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Download
              _ReelActionButton(
                icon: FontAwesomeIcons.download,
                label: "डाउनलोड",
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Download'),
                      content: const Text('Your video will be saved to the gallery.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved to gallery')),
                  );
                },
              ),
              const SizedBox(height: 16),

              // WhatsApp share
              _ReelActionButton(
                icon: FontAwesomeIcons.whatsapp,
                label: "व्हाट्सऐप",
                onTap: () async {
                  final toShare = (reel.link?.isNotEmpty ?? false)
                      ? reel.link!
                      : (reel.videoUrl.isNotEmpty ? reel.videoUrl : reel.hlsUrl);
                  final encoded = Uri.encodeComponent(toShare);
                  final uri = Uri.parse('whatsapp://send?text=$encoded');
                  try {
                    final ok = await launchUrl(uri);
                    if (!ok) {
                      onShare(); // fallback
                    }
                  } catch (_) {
                    onShare(); // fallback
                  }
                },
              ),
              const SizedBox(height: 16),

              // Generic share (system sheet)
              _ReelActionButton(
                icon: Icons.share,
                label: "शेयर",
                onTap: onShare,
              ),
            ],
          ),
        ),

        /// 🎛 Bottom playback controls
        if (showControls && hasVideo)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: _BottomControls(
              controller: controller!,
              onPlayPause: onTapAnywherePlayPause,
              onToggleMute: onToggleMute,
              requestRebuild: requestRebuild,
            ),
          ),

        /// ⏸ Center pause/play overlay
        if (showPauseOverlay)
          Center(
            child: GestureDetector(
              onTap: onCenterOverlayTap,
              child: Icon(
                (controller?.value.isPlaying ?? false)
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: Colors.white.withOpacity(0.9),
                size: 90,
              ),
            ),
          ),
      ],
    );
  }
}

/// 🎯 Helper button widget for right-side controls
class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Icon(Icons.circle, color: Colors.transparent), // will be replaced by IconTheme below
        ),
      ),
    );
  }
}

// Replace icon inside _RoundButton via IconTheme to keep ripple size consistent
// (Alternative: inline Icon(icon, color: Colors.white) inside Padding in _RoundButton)
extension on _RoundButton {
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleMute;
  final VoidCallback requestRebuild;

  const _BottomControls({
    required this.controller,
    required this.onPlayPause,
    required this.onToggleMute,
    required this.requestRebuild,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = controller.value.isPlaying;
    final isMuted = controller.value.volume == 0;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.45),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_5, color: Colors.white),
              onPressed: () async {
                final pos = controller.value.position - const Duration(seconds: 5);
                await controller.seekTo(pos > Duration.zero ? pos : Duration.zero);
                requestRebuild();
              },
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
              onPressed: () {
                onPlayPause();       // 👈 use shared toggler so all UI stays in sync
                requestRebuild();
              },
            ),
            IconButton(
              icon: const Icon(Icons.forward_5, color: Colors.white),
              onPressed: () async {
                final pos = controller.value.position + const Duration(seconds: 5);
                await controller.seekTo(pos);
                requestRebuild();
              },
            ),
            IconButton(
              icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
              onPressed: () {
                onToggleMute();
                requestRebuild();
              },
            ),
          ],
        ),
      ),
    );
  }
}

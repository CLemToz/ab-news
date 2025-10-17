import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../data/mock_data.dart';     // reels list
import '../../models/reel_item.dart';   // ReelItem model
import '../../widgets/common.dart';     // TagChip

/// Full-bleed Reels screen (like IG/YT Shorts).
/// - [initialIndex]: open at a specific reel
/// - [onExit]: if provided, shows a back button even as a tab and calls this
///             when user taps back (e.g., switch to Home tab).
class ReelsScreen extends StatefulWidget {
  final int initialIndex;
  final VoidCallback? onExit;
  const ReelsScreen({super.key, this.initialIndex = 0, this.onExit});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late final PageController _pc;
  late int _active;

  @override
  void initState() {
    super.initState();
    _active = widget.initialIndex.clamp(0, reels.length - 1);
    _pc = PageController(initialPage: _active);

    // Edge-to-edge chrome (transparent bars) for true full-bleed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    // If opened via push, pop. Else call onExit (tab flow).
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.onExit != null) {
      widget.onExit!();
      return;
    }
    // Fallback: go to app root (change '/' if your root route differs)
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBack = Navigator.of(context).canPop() || widget.onExit != null;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            scrollDirection: Axis.vertical,
            onPageChanged: (i) => setState(() => _active = i),
            itemCount: reels.length,
            itemBuilder: (_, i) => ReelTile(
              key: ValueKey(reels[i].id),
              item: reels[i],
              active: i == _active,
            ),
          ),

          if (showBack)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: GestureDetector(
                onTap: _handleBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
            ),

          const Positioned(
            top: 12,
            left: 52,
            child: Text(
              'Reels',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== TILE ============================== */

class ReelTile extends StatefulWidget {
  final ReelItem item;
  final bool active;
  const ReelTile({super.key, required this.item, required this.active});

  @override
  State<ReelTile> createState() => _ReelTileState();
}

class _ReelTileState extends State<ReelTile> {
  VideoPlayerController? _vc;
  bool _ready = false, _error = false, _muted = false, _liked = false, _saved = false;

  // minimal controls (tap to show/hide)
  bool _controlsVisible = false;
  Timer? _hideTimer;

  // progress
  Duration _pos = Duration.zero, _dur = Duration.zero;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _vc = VideoPlayerController.network(widget.item.videoUrl)
        ..setLooping(true)
        ..setVolume(_muted ? 0 : 1);

      await _vc!.initialize();
      if (!mounted) return;

      _listener = () {
        if (!mounted) return;
        setState(() {
          _pos = _vc!.value.position;
          _dur = _vc!.value.duration;
        });
      };
      _vc!.addListener(_listener);

      setState(() => _ready = true);
      if (widget.active) _vc!.play();
    } catch (_) {
      if (mounted) setState(() { _error = true; _ready = false; });
    }
  }

  @override
  void didUpdateWidget(covariant ReelTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready && !_error) {
      if (widget.active) {
        _vc?.play();
      } else {
        _vc?.pause();
        _hide(immediate: true);
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_vc != null) {
      _vc!.removeListener(_listener);
      _vc!.dispose();
    }
    super.dispose();
  }

  /* --------------------------- helpers ---------------------------- */

  void _show() { setState(() => _controlsVisible = true); _autoHide(); }
  void _hide({bool immediate = false}) {
    _hideTimer?.cancel();
    if (immediate) setState(() => _controlsVisible = false);
  }
  void _autoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _onScreenTap() {
    if (!_ready || _error) return;
    if (_controlsVisible) {
      _hide(immediate: true);
    } else {
      _show();
    }
  }

  void _togglePlayPause() {
    if (_vc!.value.isPlaying) { _vc!.pause(); } else { _vc!.play(); }
    setState(() {});
    _autoHide();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _vc!.setVolume(_muted ? 0 : 1);
    _autoHide();
  }

  void _seek(double vMs) => _vc!.seekTo(Duration(milliseconds: vMs.toInt()));
  void _toggleLike() => setState(() => _liked = !_liked);
  void _toggleSave() => setState(() => _saved = !_saved);
  void _share() => debugPrint('Share: ${widget.item.title} ${widget.item.videoUrl}');
  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  /* ------------------------------ UI ------------------------------ */

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding; // Only safe insets; no big gaps

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onScreenTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready && !_error)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _vc!.value.size.width,
                height: _vc!.value.size.height,
                child: VideoPlayer(_vc!),
              ),
            )
          else if (_error)
            Container(
              color: Colors.black,
              child: const Center(child: Icon(Icons.error_outline, color: Colors.white54, size: 48)),
            )
          else
            Stack(children: [
              Image.network(widget.item.coverImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            ]),

          // bottom gradient (tweak opacity here if you want: .85 → darker)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(.85), Colors.transparent, Colors.transparent],
                    stops: const [0, .35, 1],
                  ),
                ),
              ),
            ),
          ),

          // info text
          Positioned(
            left: 16, right: 90, bottom: 16 + pad.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TagChip(text: widget.item.category),
                const SizedBox(height: 10),
                Text(widget.item.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(widget.item.subtitle,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          // right action rail
          Positioned(
            right: 12, bottom: 16 + pad.bottom,
            child: Column(
              children: [
                _RailBtn(icon: _liked ? Icons.favorite : Icons.favorite_border, color: _liked ? Colors.red : Colors.white, label: 'Like', onTap: _toggleLike),
                const SizedBox(height: 16),
                _RailBtn(icon: _saved ? Icons.bookmark : Icons.bookmark_border, color: _saved ? Colors.yellow : Colors.white, label: 'Save', onTap: _toggleSave),
                const SizedBox(height: 16),
                _RailBtn(icon: Icons.share_outlined, color: Colors.white, label: 'Share', onTap: _share),
                const SizedBox(height: 16),
                _RailBtn(icon: _muted ? Icons.volume_off : Icons.volume_up, color: Colors.white, label: _muted ? 'Muted' : 'Sound', onTap: _toggleMute),
              ],
            ),
          ),

          // minimal controls bar (appears on tap)
          if (_ready && _controlsVisible)
            Positioned(
              left: 12, right: 12, bottom: 12 + pad.bottom,
              child: _MiniControls(
                playing: _vc!.value.isPlaying,
                muted: _muted,
                pos: _pos,
                dur: _dur,
                seek: _seek,
                togglePlay: _togglePlayPause,
                toggleMute: _toggleMute,
                fmt: _fmt,
              ),
            ),
        ],
      ),
    );
  }
}

/* ----------------- small widgets ----------------- */

class _RailBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Color color;
  const _RailBtn({required this.icon, required this.label, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}

class _MiniControls extends StatelessWidget {
  final bool playing, muted;
  final Duration pos, dur;
  final ValueChanged<double> seek;
  final VoidCallback togglePlay, toggleMute;
  final String Function(Duration) fmt;
  const _MiniControls({
    required this.playing, required this.muted, required this.pos, required this.dur,
    required this.seek, required this.togglePlay, required this.toggleMute, required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final total = (dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds).toDouble();
    final value = pos.inMilliseconds.clamp(0, total).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.55), // controls bg opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: value, min: 0, max: total,
                  onChanged: seek,
                  activeColor: Colors.white, inactiveColor: Colors.white24,
                ),
              ),
              Text(fmt(dur), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: togglePlay,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                splashRadius: 20,
              ),
              const Spacer(),
              IconButton(
                onPressed: toggleMute,
                icon: Icon(muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
